'use client';
import { useState, useEffect, useRef } from 'react';

export default function MessagesView({ session }) {
  const [messages, setMessages] = useState([]);
  const [newMessage, setNewMessage] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const messagesEndRef = useRef(null);

  useEffect(() => {
    fetchMessages();
    const interval = setInterval(fetchMessages, 5000);
    return () => clearInterval(interval);
  }, []);

  const fetchMessages = async () => {
    try {
      const res = await fetch('/api/messages');
      const data = await res.json();
      if (Array.isArray(data)) {
        setMessages(data);
      }
      setIsLoading(false);
    } catch (err) {
      console.error('Failed to fetch messages', err);
      setIsLoading(false);
    }
  };

  const handleSendMessage = async (e) => {
    e.preventDefault();
    if (!newMessage.trim()) return;
    const content = newMessage.trim();
    const tempMessage = {
      id: `temp-${Date.now()}`,
      content,
      sender: { name: session.name, id: session.id },
      created_at: new Date().toISOString()
    };

    setMessages(prev => [...prev, tempMessage]);
    setNewMessage('');
    setTimeout(() => messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' }), 100);

    try {
      await fetch('/api/messages', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ content }),
      });
      fetchMessages();
    } catch (err) {
      console.error('Failed to send message', err);
    }
  };

  const getInitials = (name) => name ? name.charAt(0).toUpperCase() : '?';

  const getColorForName = (name) => {
    const colors = ['#2563eb', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6'];
    let hash = 0;
    for (let i = 0; i < name.length; i++) {
      hash = name.charCodeAt(i) + ((hash << 5) - hash);
    }
    return colors[Math.abs(hash) % colors.length];
  };

  const formatTime = (dateString) => {
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = now - date;
    const diffMins = Math.floor(diffMs / 60000);
    if (diffMins < 1) return 'now';
    if (diffMins < 60) return `${diffMins}m`;
    const diffHours = Math.floor(diffMins / 60);
    if (diffHours < 24) return `${diffHours}h`;
    return `${Math.floor(diffHours / 24)}d`;
  };

  const filteredMessages = messages.filter(msg => {
    if (!searchQuery.trim()) return true;
    const q = searchQuery.toLowerCase();
    return (
      msg.content.toLowerCase().includes(q) ||
      msg.sender?.name?.toLowerCase().includes(q)
    );
  });

  const roleColor = { ADMIN: '#ef4444', LECTURER: '#8b5cf6', PREFECT: '#10b981', STUDENT: '#2563eb' };

  return (
    <div style={{ paddingBottom: '2rem', height: '100%', display: 'flex', flexDirection: 'column' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.25rem' }}>
        <h2 style={{ fontSize: '1.75rem', fontWeight: '800', color: 'var(--text-primary)' }}>Campus Chat</h2>
        <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)', background: 'var(--surface-color)', border: '1px solid var(--border-color)', borderRadius: '999px', padding: '0.25rem 0.75rem' }}>
          {messages.length} messages
        </span>
      </div>
      <p style={{ color: 'var(--text-secondary)', marginBottom: '1.5rem', fontSize: '0.9rem' }}>
        Broadcast channel — all users can read and write
      </p>

      <input
        type="text"
        placeholder="Search messages or people..."
        value={searchQuery}
        onChange={(e) => setSearchQuery(e.target.value)}
        style={{
          width: '100%',
          padding: '0.85rem 1.25rem',
          borderRadius: '9999px',
          border: '1px solid var(--border-color)',
          backgroundColor: 'var(--surface-color)',
          color: 'var(--text-primary)',
          marginBottom: '1.25rem',
          outline: 'none',
          fontSize: '0.95rem'
        }}
      />

      <div style={{ flex: 1, overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '0.5rem', paddingBottom: '5rem' }}>
        {isLoading ? (
          <div style={{ textAlign: 'center', color: 'var(--text-muted)', padding: '3rem' }}>Loading messages...</div>
        ) : filteredMessages.length === 0 ? (
          <div style={{ textAlign: 'center', color: 'var(--text-muted)', padding: '3rem' }}>
            {searchQuery ? 'No messages match your search.' : 'No messages yet. Be the first!'}
          </div>
        ) : (
          filteredMessages.map((msg) => {
            const isMe = msg.sender?.id === session.id;
            const senderColor = getColorForName(msg.sender?.name || '');
            return (
              <div key={msg.id} style={{
                display: 'flex',
                flexDirection: isMe ? 'row-reverse' : 'row',
                alignItems: 'flex-end',
                gap: '0.5rem'
              }}>
                {!isMe && (
                  <div style={{
                    width: '36px', height: '36px', borderRadius: '50%',
                    backgroundColor: senderColor, color: 'white',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    fontWeight: 'bold', fontSize: '1rem', flexShrink: 0
                  }}>
                    {getInitials(msg.sender?.name)}
                  </div>
                )}
                <div style={{ maxWidth: '70%' }}>
                  {!isMe && (
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.25rem' }}>
                      <span style={{ fontSize: '0.8rem', fontWeight: '700', color: senderColor }}>{msg.sender?.name}</span>
                      {msg.sender?.role && (
                        <span style={{ fontSize: '0.65rem', fontWeight: '600', color: 'white', backgroundColor: roleColor[msg.sender.role] || '#94a3b8', borderRadius: '999px', padding: '0.1rem 0.4rem' }}>
                          {msg.sender.role}
                        </span>
                      )}
                    </div>
                  )}
                  <div style={{
                    padding: '0.65rem 1rem',
                    borderRadius: isMe ? '16px 16px 4px 16px' : '16px 16px 16px 4px',
                    backgroundColor: isMe ? 'var(--primary-blue)' : 'var(--surface-color)',
                    color: isMe ? 'white' : 'var(--text-primary)',
                    border: isMe ? 'none' : '1px solid var(--border-color)',
                    fontSize: '0.95rem',
                    lineHeight: 1.4
                  }}>
                    {msg.content}
                  </div>
                  <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)', marginTop: '0.2rem', textAlign: isMe ? 'right' : 'left' }}>
                    {formatTime(msg.created_at)}
                  </div>
                </div>
              </div>
            );
          })
        )}
        <div ref={messagesEndRef} />
      </div>

      <form onSubmit={handleSendMessage} style={{
        position: 'fixed',
        bottom: '1.5rem',
        left: '300px',
        right: '2.5rem',
        display: 'flex',
        gap: '0.75rem',
        zIndex: 40
      }}>
        <input
          type="text"
          value={newMessage}
          onChange={(e) => setNewMessage(e.target.value)}
          placeholder="Type a message to the campus..."
          style={{
            flex: 1,
            padding: '1rem 1.25rem',
            borderRadius: '9999px',
            border: '1px solid var(--border-color)',
            backgroundColor: 'var(--surface-color)',
            color: 'var(--text-primary)',
            outline: 'none',
            fontSize: '0.95rem',
            boxShadow: '0 4px 12px rgba(0,0,0,0.1)'
          }}
        />
        <button type="submit" style={{
          backgroundColor: 'var(--primary-blue)',
          color: 'white',
          border: 'none',
          borderRadius: '50%',
          width: '52px',
          height: '52px',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          cursor: 'pointer',
          flexShrink: 0,
          boxShadow: '0 4px 12px rgba(30,58,138,0.3)',
          transition: 'transform 0.1s'
        }}>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <line x1="22" y1="2" x2="11" y2="13"></line>
            <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
          </svg>
        </button>
      </form>
    </div>
  );
}
