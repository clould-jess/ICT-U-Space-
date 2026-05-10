'use client';
import { useState } from 'react';
import SettingsButton from './SettingsButton';

const Icon = ({ d, viewBox = "0 0 24 24" }) => (
  <svg width="18" height="18" viewBox={viewBox} fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    {typeof d === 'string' ? <path d={d} /> : d}
  </svg>
);

const NAV = {
  ADMIN: [
    { id: 'halls',     label: 'Manage Spaces',   icon: <Icon d={<><rect x="4" y="2" width="16" height="20" rx="2"/><path d="M9 22v-4h6v4M8 6h.01M16 6h.01M12 6h.01M12 10h.01M12 14h.01M16 10h.01M16 14h.01M8 10h.01M8 14h.01"/></>} /> },
    { id: 'courses',   label: 'Manage Courses',  icon: <Icon d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H20v20H6.5a2.5 2.5 0 0 1 0-5H20" /> },
    { id: 'timetable', label: 'Timetable',        icon: <Icon d={<><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></>} /> },
    { id: 'users',     label: 'Users',            icon: <Icon d={<><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/></>} /> },
    { id: 'messages',  label: 'Campus Chat',      icon: <Icon d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" /> },
  ],
  STUDENT: [
    { id: 'dashboard',    label: 'Dashboard',    icon: <Icon d={<><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></>} /> },
    { id: 'timetable',    label: 'My Timetable', icon: <Icon d={<><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></>} /> },
    { id: 'reservations', label: 'Reservations', icon: <Icon d={<><path d="M8 2v4M16 2v4M3 10h18M21 8a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V10a2 2 0 0 1 2-2z"/><path d="m9 16 2 2 4-4"/></>} /> },
    { id: 'rooms',        label: 'Find Rooms',   icon: <Icon d={<><path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/></>} /> },
    { id: 'messages',     label: 'Campus Chat',  icon: <Icon d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" /> },
  ],
  LECTURER: [
    { id: 'dashboard', label: 'Dashboard',     icon: <Icon d={<><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></>} /> },
    { id: 'courses',   label: 'My Courses',    icon: <Icon d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H20v20H6.5a2.5 2.5 0 0 1 0-5H20" /> },
    { id: 'messages',  label: 'Campus Chat',   icon: <Icon d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" /> },
  ],
  PREFECT: [
    { id: 'dashboard', label: 'Dashboard',     icon: <Icon d={<><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></>} /> },
    { id: 'reserve',   label: 'Reserve Space', icon: <Icon d={<><rect x="4" y="2" width="16" height="20" rx="2"/><path d="M9 22v-4h6v4M8 6h.01M16 6h.01M12 6h.01M12 10h.01M12 14h.01M16 10h.01M16 14h.01M8 10h.01M8 14h.01"/></>} /> },
    { id: 'rooms',     label: 'Find Rooms',    icon: <Icon d={<><path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/></>} /> },
    { id: 'messages',  label: 'Campus Chat',   icon: <Icon d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" /> },
  ],
};

export default function Sidebar({ session, activeTab, setActiveTab, isOpen }) {
  const navLinks = NAV[session.role] || NAV.STUDENT;

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
      zIndex: 40,
      flexShrink: 0
    }}>
      <div style={{ width: '260px', height: '100%', display: 'flex', flexDirection: 'column', padding: '1.5rem 1rem', color: '#e3e3e3' }}>

        {/* Logo */}
        <div style={{ padding: '0.75rem 1rem', marginBottom: '1.5rem', color: '#fff', fontSize: '1.4rem', fontWeight: 'bold', textAlign: 'center', borderBottom: '1px solid #333', paddingBottom: '1rem' }}>
          ICT-U Space
        </div>

        {/* User info pill */}
        <div style={{ background: 'rgba(255,255,255,0.06)', borderRadius: '10px', padding: '0.75rem', marginBottom: '1.25rem', display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
          <div style={{ width: '32px', height: '32px', borderRadius: '50%', background: 'var(--primary-blue)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 'bold', fontSize: '1rem', color: 'white', flexShrink: 0 }}>
            {session.name.charAt(0).toUpperCase()}
          </div>
          <div style={{ minWidth: 0 }}>
            <div style={{ fontSize: '0.85rem', fontWeight: '600', color: '#fff', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{session.name}</div>
            <div style={{ fontSize: '0.72rem', color: '#888' }}>{session.role}</div>
          </div>
        </div>

        {/* Nav links */}
        <div style={{ flex: 1, overflowY: 'auto' }}>
          <ul style={{ listStyle: 'none', padding: 0, margin: 0, display: 'flex', flexDirection: 'column', gap: '0.25rem' }}>
            {navLinks.map(link => (
              <li key={link.id}>
                <button
                  onClick={() => setActiveTab(link.id)}
                  style={{
                    width: '100%', textAlign: 'left', padding: '0.65rem 0.75rem',
                    backgroundColor: activeTab === link.id ? 'rgba(255,255,255,0.12)' : 'transparent',
                    color: activeTab === link.id ? '#fff' : '#a3a3a3',
                    border: activeTab === link.id ? '1px solid rgba(255,255,255,0.1)' : '1px solid transparent',
                    borderRadius: '8px', fontSize: '0.92rem',
                    display: 'flex', alignItems: 'center', gap: '0.75rem',
                    cursor: 'pointer', transition: 'all 0.15s',
                    fontWeight: activeTab === link.id ? '600' : '400'
                  }}
                  onMouseOver={e => { if (activeTab !== link.id) { e.currentTarget.style.backgroundColor = 'rgba(255,255,255,0.06)'; e.currentTarget.style.color = '#fff'; } }}
                  onMouseOut={e => { if (activeTab !== link.id) { e.currentTarget.style.backgroundColor = 'transparent'; e.currentTarget.style.color = '#a3a3a3'; } }}
                >
                  <span style={{ opacity: activeTab === link.id ? 1 : 0.7 }}>{link.icon}</span>
                  {link.label}
                </button>
              </li>
            ))}
          </ul>
        </div>

        {/* Bottom: settings + logout */}
        <div style={{ borderTop: '1px solid #333', paddingTop: '1rem', marginTop: '1rem', display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
          {(session.role === 'STUDENT' || session.role === 'LECTURER' || session.role === 'PREFECT') && (
            <SettingsButton session={session} />
          )}
          <form action="/api/auth/logout" method="POST">
            <button type="submit" style={{
              width: '100%', padding: '0.6rem',
              background: 'rgba(239, 68, 68, 0.1)', border: '1px solid rgba(239, 68, 68, 0.3)', borderRadius: '6px',
              color: '#ef4444', fontSize: '0.9rem', cursor: 'pointer', transition: 'all 0.2s', fontWeight: '600',
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem'
            }}
            onMouseOver={e => { e.currentTarget.style.backgroundColor = 'rgba(239, 68, 68, 0.2)'; }}
            onMouseOut={e => { e.currentTarget.style.backgroundColor = 'rgba(239, 68, 68, 0.1)'; }}
            >
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9"/></svg>
              Log Out
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
