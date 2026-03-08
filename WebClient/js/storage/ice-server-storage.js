/**
 * ice-server-storage.js - Persist user-defined ICE servers in localStorage.
 */

const STORAGE_KEY = 'quickdesk_user_ice_servers';

export class IceServerStorage {
    /**
     * @returns {Array<{urls: string, username?: string, credential?: string}>}
     */
    static getAll() {
        try {
            const raw = localStorage.getItem(STORAGE_KEY);
            return raw ? JSON.parse(raw) : [];
        } catch {
            return [];
        }
    }

    /**
     * @returns {boolean}
     */
    static addTurnServer(url, username, credential) {
        if (!url || !username || !credential) return false;
        if (!url.startsWith('turn:') && !url.startsWith('turns:')) return false;

        const servers = IceServerStorage.getAll();
        if (servers.some(s => s.urls === url)) return false;

        servers.push({ urls: url, username, credential });
        IceServerStorage._save(servers);
        return true;
    }

    /**
     * @returns {boolean}
     */
    static addStunServer(url) {
        if (!url) return false;
        if (!url.startsWith('stun:') && !url.startsWith('stuns:')) return false;

        const servers = IceServerStorage.getAll();
        if (servers.some(s => s.urls === url)) return false;

        servers.push({ urls: url });
        IceServerStorage._save(servers);
        return true;
    }

    static removeAt(index) {
        const servers = IceServerStorage.getAll();
        if (index < 0 || index >= servers.length) return;
        servers.splice(index, 1);
        IceServerStorage._save(servers);
    }

    static clear() {
        localStorage.removeItem(STORAGE_KEY);
    }

    static hasTurn() {
        return IceServerStorage.getAll().some(server => {
            const url = Array.isArray(server.urls) ? server.urls[0] : server.urls;
            return url && (url.startsWith('turn:') || url.startsWith('turns:'));
        });
    }

    /** @private */
    static _save(servers) {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(servers));
    }
}
