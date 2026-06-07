'use client';
import { useState } from 'react';
import SettingsButton from './SettingsButton';

export default function Sidebar({ session, activeTab, setActiveTab, isOpen }) {
  const [discussionsCollapsed, setDiscussionsCollapsed] = useState(false);

  const navLinks = [];
  if (session.role === 'ADMIN') {
    navLinks.push(
      { id: 'halls', label: 'Manage Spaces', icon: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="4" y="2" width="16" height="20" rx="2" ry="2"></rect><path d="M9 22v-4h6v4"></path><path d="M8 6h.01"></path><path d="M16 6h.01"></path><path d="M12 6h.01"></path><path d="M12 10h.01"></path><path d="M12 14h.01"></path><path d="M16 10h.01"></path><path d="M16 14h.01"></path><path d="M8 10h.01"></path><path d="M8 14h.01"></path></svg> },
      { id: 'courses', label: 'Manage Courses', icon: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H20v20H6.5a2.5 2.5 0 0 1 0-5H20"></path></svg> },
      { id: 'reservations', label: 'Reservations', icon: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg> },
      { id: 'users', label: 'User Management', icon: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M22 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg> }
    );
  } else if (session.role === 'STUDENT') {
    navLinks.push(
      { id: 'dashboard', label: 'Dashboard', icon: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path><polyline points="9 22 9 12 15 12 15 22"></polyline></svg> },
      { id: 'timetable', label: 'My Timetable', icon: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg> }
    );
  } else if (session.role === 'LECTURER') {
    navLinks.push(
      { id: 'dashboard', label: 'Dashboard', icon: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path><polyline points="9 22 9 12 15 12 15 22"></polyline></svg> },
      { id: 'courses', label: 'My Courses', icon: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H20v20H6.5a2.5 2.5 0 0 1 0-5H20"></path></svg> }
    );
  }

  return (
    <div style={{
      width: isOpen ? '260px' : '0px',
      minWidth: isOpen ? '260px' : '0px',
      height: '100vh',
      backgroundColor: 'rgba(30, 30, 30, 0.75)',
      backdropFilter: 'blur(16px)',
      WebkitBackdropFilter: 'blur(16px)',
      borderRight: isOpen ? '1px solid rgba(255,255,255,0.1)' : 'none',
      transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
      overflow: 'hidden',
      position: 'relative',
      zIndex: 40
    }}>
      <div style={{
        width: '260px',
        height: '100%',
        display: 'flex',
        flexDirection: 'column',
        padding: '1.5rem 1rem',
        color: '#e3e3e3',
        fontFamily: 'var(--font-geist-sans), sans-serif',
      }}>
      <div style={{
        padding: '0.75rem 1rem',
        marginBottom: '1.5rem',
        color: '#fff',
        fontSize: '1.5rem',
        fontWeight: 'bold',
        textAlign: 'center',
        borderBottom: '1px solid #333',
        paddingBottom: '1rem'
      }}>
        ICT-U Space
      </div>

      <div style={{ flex: 1, overflowY: 'auto' }}>
        <ul style={{ listStyle: 'none', padding: 0, margin: 0, display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
          {navLinks.map(link => (
            <li key={link.id}>
              <button
                onClick={() => setActiveTab(link.id)}
                style={{
                  width: '100%', textAlign: 'left', padding: '0.6rem 0.75rem',
                  backgroundColor: activeTab === link.id ? '#2a2a2a' : 'transparent',
                  color: activeTab === link.id ? '#fff' : '#a3a3a3',
                  border: 'none', borderRadius: '6px', fontSize: '0.95rem',
                  display: 'flex', alignItems: 'center', gap: '0.75rem',
                  cursor: 'pointer', transition: 'all 0.2s'
                }}
                onMouseOver={e => { if (activeTab !== link.id) { e.currentTarget.style.backgroundColor = '#222'; e.currentTarget.style.color = '#fff'; } }}
                onMouseOut={e => { if (activeTab !== link.id) { e.currentTarget.style.backgroundColor = 'transparent'; e.currentTarget.style.color = '#a3a3a3'; } }}
              >
                <span>{link.icon}</span>
                {link.label}
              </button>
            </li>
          ))}
        </ul>

      </div>

      <div style={{ borderTop: '1px solid #333', paddingTop: '1rem', marginTop: '1rem' }}>
        <form action="/api/auth/logout" method="POST">
          <button type="submit" style={{
            width: '100%', padding: '0.6rem',
            background: 'rgba(239, 68, 68, 0.1)', border: '1px solid rgba(239, 68, 68, 0.3)', borderRadius: '6px',
            color: '#ef4444', fontSize: '0.9rem', cursor: 'pointer',
            transition: 'all 0.2s', fontWeight: 'bold'
          }}
          onMouseOver={e => { e.currentTarget.style.backgroundColor = 'rgba(239, 68, 68, 0.2)'; }}
          onMouseOut={e => { e.currentTarget.style.backgroundColor = 'rgba(239, 68, 68, 0.1)'; }}
          >
            Log Out
          </button>
        </form>
      </div>
      </div>
    </div>
  );
}
