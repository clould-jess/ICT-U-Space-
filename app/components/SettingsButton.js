'use client';
import { useState } from 'react';
import SettingsModal from './SettingsModal';

export default function SettingsButton({ session }) {
  const [isOpen, setIsOpen] = useState(false);
  
  return (
    <>
      <button 
        onClick={() => setIsOpen(true)}
        style={{ background: 'none', border: 'none', cursor: 'pointer', padding: '0.25rem', display: 'flex', alignItems: 'center', justifyContent: 'center' }}
        title="Settings"
      >
        <span style={{ fontSize: '1.5rem' }}>⚙️</span>
      </button>
      
      {isOpen && <SettingsModal session={session} onClose={() => { setIsOpen(false); window.location.reload(); }} />}
    </>
  );
}
