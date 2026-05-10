'use client';
import { useState, useEffect, useRef } from 'react';

export default function MessagesView({ session }) {
  const [messages, setMessages] = useState([]);
  const [newMessage, setNewMessage] = useState('');
  const [isLoading, setIsLoading] = useState(true);
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
      setMessages(data);
      setIsLoading(false);
    } catch (err) {
      console.error('Failed to fetch messages', err);
    }
  };

  const handleSendMessage = async (e) => {
    e.preventDefault();
    if (!newMessage.trim()) return;

    const tempMessage = {
      id: Date.now(),
      content: newMessage,
      sender: { name: session.name, id: session.id },
      created_at: new Date().toISOString()
    };
    
    setMessages(prev => [...prev, tempMessage]);
    setNewMessage('');
    setTimeout(() => messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' }), 100);

    try {
      await fetch('/api/messages/send', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ content: tempMessage.content }),
      });
      fetchMessages();
    } catch (err) {
      console.error('Failed to send message', err);
    }
  };

  const getInitials = (name) => {
    return name ? name.charAt(0).toUpperCase() : '?';
  };

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
    
    if (diffMins < 60) return `${Math.max(1, diffMins)}m`;
    const diffHours = Math.floor(diffMins / 60);
    if (diffHours < 24) return `${diffHours}h`;
    return `${Math.floor(diffHours / 24)}d`;
  };

  return (
    <div style={{ paddingBottom: '2rem' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.25rem' }}>
        <h2 style={{ fontSize: '1.75rem', fontWeight: '800', color: 'var(--text-primary)' }}>Inbox</h2>
      </div>
      <p style={{ color: 'var(--text-secondary)', marginBottom: '1.5rem' }}>Your notifications and alerts</p>

      {/* Search Bar */}
      <input 
        type="text" 
        placeholder="Search messages" 
        style={{
          width: '100%',
          padding: '1rem',
          borderRadius: '9999px',
          border: '1px solid var(--border-color)',
          backgroundColor: 'white',
          marginBottom: '1.5rem',
          outline: 'none',
          fontSize: '0.95rem'
        }}
      />

      <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem', paddingBottom: '6rem' }}>
        {isLoading ? (
          <p style={{ textAlign: 'center', color: 'var(--text-muted)', padding: '2rem' }}>Loading messages...</p>
        ) : messages.length === 0 ? (
          <p style={{ textAlign: 'center', color: 'var(--text-muted)', padding: '2rem' }}>No messages yet.</p>
        ) : (
          messages.map((msg, i) => {
            const isMe = msg.sender.id === session.id;
            return (
              <div key={msg.id} className="card" style={{ padding: '1rem', display: 'flex', gap: '1rem', alignItems: 'center' }}>
                <div style={{
                  width: '45px',
                  height: '45px',
                  borderRadius: '50%',
                  backgroundColor: getColorForName(msg.sender.name),
                  color: 'white',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontWeight: 'bold',
                  fontSize: '1.2rem',
                  flexShrink: 0
                }}>
                  {getInitials(msg.sender.name)}
                </div>
                
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: '0.25rem' }}>
                    <h4 style={{ fontWeight: '700', fontSize: '1rem', color: 'var(--text-primary)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                      {isMe ? 'You' : msg.sender.name}
                    </h4>
                    <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                      {formatTime(msg.created_at)}
                    </span>
                  </div>
                  <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                    {msg.content}
                  </p>
                </div>
              </div>
            );
          })
        )}
        <div ref={messagesEndRef} />
      </div>

      {/* Floating compose bar (simplified for mobile) */}
      <form onSubmit={handleSendMessage} style={{
        position: 'fixed',
        bottom: '5rem', /* Above bottom nav */
        left: '1rem',
        right: '1rem',
        display: 'flex',
        gap: '0.5rem',
        backgroundColor: 'var(--bg-color)',
        padding: '0.5rem 0',
        zIndex: 40
      }}>
        <input
          type="text"
          value={newMessage}
          onChange={(e) => setNewMessage(e.target.value)}
          placeholder="Type a message..."
          style={{
            flex: 1,
            padding: '1rem',
            borderRadius: '9999px',
            border: '1px solid var(--border-color)',
            outline: 'none',
            fontSize: '0.95rem'
          }}
        />
        <button type="submit" style={{
          backgroundColor: 'var(--primary-blue)',
          color: 'white',
          border: 'none',
          borderRadius: '50%',
          width: '50px',
          height: '50px',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          cursor: 'pointer'
        }}>
          ➤
        </button>
      </form>
    </div>
  );
}
