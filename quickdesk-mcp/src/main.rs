mod config;
mod event_bus;
mod http_transport;
mod server;
mod ws_client;

use clap::Parser;
use config::{AppConfig, TransportMode};
use event_bus::EventBus;
use rmcp::ServiceExt;
use rmcp::transport::stdio;
use tracing_subscriber::EnvFilter;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::from_default_env())
        .with_writer(std::io::stderr)
        .init();

    let config = AppConfig::parse();

    tracing::info!("Connecting to QuickDesk at {}", config.ws_url);

    // Create event bus for WebSocket event bridging (caches up to 500 recent events)
    let event_bus = EventBus::new(500);

    let auth_token = config.auth_token();
    let ws = ws_client::WsClient::connect(&config.ws_url, auth_token, event_bus).await?;

    if let Some(ref devices) = config.allowed_devices {
        tracing::info!("Allowed devices: {:?}", devices);
    }
    if config.rate_limit > 0 {
        tracing::info!("Rate limit: {} requests/minute", config.rate_limit);
    }
    if config.session_timeout > 0 {
        tracing::info!("Session timeout: {}s", config.session_timeout);
    }

    match config.transport {
        TransportMode::Stdio => {
            tracing::info!("Starting MCP server on stdio...");
            let mcp_server = server::QuickDeskMcpServer::new(
                ws,
                config.allowed_devices.unwrap_or_default(),
            );
            let service = mcp_server.serve(stdio()).await?;
            service.waiting().await?;
        }
        TransportMode::Http => {
            http_transport::start_http(&config, ws).await?;
        }
    }

    Ok(())
}
