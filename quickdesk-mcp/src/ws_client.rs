use futures_util::{SinkExt, StreamExt};
use serde_json::Value;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::{Mutex, oneshot};
use tokio_tungstenite::{connect_async, tungstenite::Message};

use crate::event_bus::{Event, EventBus};

type PendingRequests = Arc<Mutex<HashMap<String, oneshot::Sender<Result<Value, String>>>>>;

#[derive(Clone)]
pub struct WsClient {
    sender: Arc<Mutex<futures_util::stream::SplitSink<
        tokio_tungstenite::WebSocketStream<
            tokio_tungstenite::MaybeTlsStream<tokio::net::TcpStream>,
        >,
        Message,
    >>>,
    pending: PendingRequests,
    req_counter: Arc<Mutex<u64>>,
    event_bus: EventBus,
}

impl WsClient {
    pub async fn connect(url: &str, token: Option<&str>, event_bus: EventBus) -> Result<Self, String> {
        let (ws_stream, _) = connect_async(url)
            .await
            .map_err(|e| format!("WebSocket connect failed: {e}"))?;

        let (write, read) = ws_stream.split();
        let pending: PendingRequests = Arc::new(Mutex::new(HashMap::new()));

        let client = Self {
            sender: Arc::new(Mutex::new(write)),
            pending: pending.clone(),
            req_counter: Arc::new(Mutex::new(0)),
            event_bus: event_bus.clone(),
        };

        // Spawn reader task to dispatch responses and events
        tokio::spawn(Self::reader_loop(read, pending, event_bus));

        // Authenticate if token provided
        if let Some(token) = token {
            client.authenticate(token).await?;
        }

        Ok(client)
    }

    async fn authenticate(&self, token: &str) -> Result<(), String> {
        let resp = self
            .request(
                "auth",
                serde_json::json!({ "token": token }),
            )
            .await?;

        if resp.get("authenticated").and_then(|v| v.as_bool()) == Some(true) {
            Ok(())
        } else {
            Err("Authentication failed".to_string())
        }
    }

    pub async fn request(&self, method: &str, params: Value) -> Result<Value, String> {
        let id = {
            let mut counter = self.req_counter.lock().await;
            *counter += 1;
            format!("req_{}", *counter)
        };

        let msg = serde_json::json!({
            "id": id,
            "method": method,
            "params": params,
        });

        let (tx, rx) = oneshot::channel();
        {
            self.pending.lock().await.insert(id.clone(), tx);
        }

        {
            let text = serde_json::to_string(&msg).unwrap();
            self.sender
                .lock()
                .await
                .send(Message::Text(text.into()))
                .await
                .map_err(|e| format!("WebSocket send failed: {e}"))?;
        }

        rx.await.map_err(|_| "Response channel closed".to_string())?
    }

    async fn reader_loop(
        mut read: futures_util::stream::SplitStream<
            tokio_tungstenite::WebSocketStream<
                tokio_tungstenite::MaybeTlsStream<tokio::net::TcpStream>,
            >,
        >,
        pending: PendingRequests,
        event_bus: EventBus,
    ) {
        while let Some(msg) = read.next().await {
            let msg = match msg {
                Ok(Message::Text(t)) => t,
                Ok(Message::Close(_)) => break,
                Err(_) => break,
                _ => continue,
            };

            let parsed: Value = match serde_json::from_str(&msg) {
                Ok(v) => v,
                Err(_) => continue,
            };

            // Handle responses with "id" field (request-response pattern)
            if let Some(id) = parsed.get("id").and_then(|v| v.as_str()) {
                let mut map = pending.lock().await;
                if let Some(tx) = map.remove(id) {
                    if let Some(err) = parsed.get("error") {
                        let msg = err
                            .get("message")
                            .and_then(|v| v.as_str())
                            .unwrap_or("Unknown error");
                        let _ = tx.send(Err(msg.to_string()));
                    } else if let Some(result) = parsed.get("result") {
                        let _ = tx.send(Ok(result.clone()));
                    } else {
                        let _ = tx.send(Ok(parsed));
                    }
                }
            }
            // Handle event pushes (messages with "event" field, no "id")
            else if let Some(event_name) = parsed.get("event").and_then(|v| v.as_str()) {
                let data = parsed.get("data").cloned().unwrap_or(Value::Null);
                let timestamp = std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .unwrap_or_default()
                    .as_millis() as u64;

                tracing::debug!("Received event: {} data={}", event_name, data);

                event_bus
                    .publish(Event {
                        event: event_name.to_string(),
                        data,
                        timestamp,
                    })
                    .await;
            }
        }
    }

    /// Get a reference to the event bus
    pub fn event_bus(&self) -> &EventBus {
        &self.event_bus
    }
}
