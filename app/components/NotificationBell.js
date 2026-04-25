'use client';
import { useState, useEffect } from 'react';

export default function NotificationBell() {
  const [notifications, setNotifications] = useState([]);
  const [isOpen, setIsOpen] = useState(false);
  const [unread, setUnread] = useState(0);

  useEffect(() => {
    fetch('/api/notifications')
      .then(res => res.json())
      .then(data => {
        if (Array.isArray(data)) {
          setNotifications(data);
          setUnread(data.length); 
        }
      });
  }, []);

  return (
    <div style={{ position: 'relative' }}>
      <button 
        onClick={() => { setIsOpen(!isOpen); setUnread(0); }}
        style={{ background: 'none', border: 'none', cursor: 'pointer', position: 'relative', padding: '0.25rem', display: 'flex', alignItems: 'center', justifyContent: 'center' }}
      >
        <span style={{ fontSize: '1.5rem' }}>🔔</span>
        {unread > 0 && (
          <span style={{ position: 'absolute', top: '-5px', right: '-5px', background: 'var(--accent-orange)', color: 'white', borderRadius: '50%', width: '18px', height: '18px', fontSize: '0.65rem', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 'bold', boxShadow: '0 2px 4px rgba(0,0,0,0.2)' }}>
            {unread}
          </span>
        )}
      </button>

      {isOpen && (
        <div style={{ position: 'absolute', top: 'calc(100% + 10px)', right: '-50px', width: '320px', background: 'var(--surface-color)', borderRadius: '12px', boxShadow: '0 10px 25px rgba(0,0,0,0.1)', border: '1px solid var(--border-color)', zIndex: 100, maxHeight: '400px', overflowY: 'auto' }}>
          <div style={{ padding: '1rem', borderBottom: '1px solid var(--border-color)', fontWeight: 'bold', color: 'var(--primary-blue)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span>Notifications</span>
            {unread > 0 && <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{unread} new</span>}
          </div>
          {notifications.length === 0 ? (
            <div style={{ padding: '2rem', textAlign: 'center', color: 'var(--text-muted)', fontSize: '0.9rem' }}>No new notifications</div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column' }}>
              {notifications.map(n => (
                <div key={n.id} style={{ padding: '1rem', borderBottom: '1px solid var(--border-color)', fontSize: '0.875rem' }}>
                  <p style={{ color: 'var(--text-primary)', marginBottom: '0.35rem', lineHeight: 1.4 }}>{n.message}</p>
                  <span style={{ color: 'var(--text-muted)', fontSize: '0.75rem' }}>{new Date(n.created_at).toLocaleString()}</span>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
