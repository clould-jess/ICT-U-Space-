'use client';
import { useState, useEffect } from 'react';
import NotificationBell from './NotificationBell';
import ProfileAvatar from './ProfileAvatar';

export default function PrefectDashboard({ session, initialHalls, initialCourses, activeTab }) {
  const [selectedHall, setSelectedHall] = useState(null);
  const [date, setDate] = useState('');
  const [startTime, setStartTime] = useState('');
  const [endTime, setEndTime] = useState('');
  const [selectedCourseId, setSelectedCourseId] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [alternatives, setAlternatives] = useState([]);
  const [success, setSuccess] = useState('');
  const [hallStatuses, setHallStatuses] = useState([]);
  const [loadingRooms, setLoadingRooms] = useState(false);

  const fetchRoomStatuses = async () => {
    setLoadingRooms(true);
    try {
      const res = await fetch('/api/halls/status');
      const data = await res.json();
      if (Array.isArray(data)) setHallStatuses(data);
    } catch {}
    setLoadingRooms(false);
  };

  useEffect(() => {
    if (activeTab === 'rooms') fetchRoomStatuses();
  }, [activeTab]);

  const handleReserve = async (force_booking = false) => {
    if (!date || !startTime || !endTime || !selectedCourseId) {
      setError('Please fill in all fields');
      return;
    }
    setLoading(true);
    setError('');
    setAlternatives([]);
    setSuccess('');

    try {
      const res = await fetch('/api/reservations', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          date, start_time: startTime, end_time: endTime,
          course_id: selectedCourseId, hall_id: selectedHall.id, force_booking
        })
      });
      const data = await res.json();

      if (res.status === 409) {
        setError(data.message);
        setAlternatives(data.alternatives || []);
      } else if (!res.ok) {
        setError(data.error || 'Failed to reserve');
      } else {
        setSuccess('Reservation confirmed!');
        setTimeout(() => { setSelectedHall(null); setSuccess(''); }, 2000);
      }
    } catch {
      setError('An unexpected error occurred');
    } finally {
      setLoading(false);
    }
  };

  // --- ROOMS TAB ---
  if (activeTab === 'rooms') {
    const freeCount = hallStatuses.filter(h => h.status === 'free').length;
    return (
      <div style={{ paddingBottom: '2rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
          <div>
            <h2 style={{ fontSize: '1.75rem', fontWeight: '800', color: 'var(--text-primary)' }}>Available Rooms</h2>
            <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>Live room status on campus</p>
          </div>
          <div style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
            <button onClick={fetchRoomStatuses} style={{ background: 'var(--surface-color)', border: '1px solid var(--border-color)', borderRadius: '8px', padding: '0.5rem 1rem', cursor: 'pointer', fontSize: '0.85rem', color: 'var(--text-secondary)' }}>Refresh</button>
            <NotificationBell />
            <ProfileAvatar session={session} />
          </div>
        </div>

        {hallStatuses.length > 0 && (
          <div style={{ display: 'flex', gap: '1rem', marginBottom: '1.5rem' }}>
            {[{ label: 'Free', count: freeCount, color: 'var(--success)' }, { label: 'Occupied', count: hallStatuses.length - freeCount, color: 'var(--error)' }].map(s => (
              <div key={s.label} className="card" style={{ flex: 1, padding: '1rem', textAlign: 'center' }}>
                <div style={{ fontSize: '2rem', fontWeight: '800', color: s.color }}>{s.count}</div>
                <div style={{ color: 'var(--text-secondary)', fontSize: '0.85rem' }}>{s.label}</div>
              </div>
            ))}
          </div>
        )}

        {loadingRooms ? (
          <div className="card" style={{ textAlign: 'center', padding: '3rem' }}><p style={{ color: 'var(--text-muted)' }}>Loading...</p></div>
        ) : (
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: '1rem' }}>
            {hallStatuses.map(hall => (
              <div key={hall.id} className="card" style={{ padding: '1.25rem', borderLeft: `4px solid ${hall.status === 'free' ? 'var(--success)' : 'var(--error)'}`, borderTopLeftRadius: '8px', borderBottomLeftRadius: '8px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.5rem' }}>
                  <h4 style={{ fontWeight: '700' }}>{hall.name}</h4>
                  <span style={{ padding: '0.2rem 0.6rem', borderRadius: '999px', fontSize: '0.75rem', fontWeight: '700', backgroundColor: hall.status === 'free' ? '#d1fae5' : '#fee2e2', color: hall.status === 'free' ? '#065f46' : '#b91c1c' }}>
                    {hall.status === 'free' ? 'Free' : 'Busy'}
                  </span>
                </div>
                <p style={{ color: 'var(--text-secondary)', fontSize: '0.82rem' }}>{hall.building_block} • {hall.capacity} seats</p>
              </div>
            ))}
          </div>
        )}
      </div>
    );
  }

  // --- RESERVE TAB ---
  if (activeTab === 'reserve') {
    return (
      <div>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '0.25rem' }}>
              <h2 style={{ fontSize: '2rem', fontWeight: '800', color: 'var(--primary-blue)' }}>Reserve a Space</h2>
              <span style={{ background: 'var(--accent-orange)', color: 'white', borderRadius: '999px', fontSize: '0.7rem', fontWeight: '700', padding: '0.2rem 0.6rem' }}>PREFECT</span>
            </div>
            <p style={{ color: 'var(--text-secondary)' }}>Book a hall on behalf of your class</p>
          </div>
          <div style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
            <NotificationBell />
            <ProfileAvatar session={session} />
          </div>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: '2rem' }}>
          {initialHalls.map(hall => (
            <div key={hall.id} className="card" style={{ display: 'flex', flexDirection: 'column' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1rem' }}>
                <h3 style={{ fontSize: '1.4rem', fontWeight: '700' }}>{hall.name}</h3>
                <span className="badge badge-orange">{hall.capacity} seats</span>
              </div>
              <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem', marginBottom: '1.5rem', flex: 1 }}>
                {hall.building_block} • {hall.features.split(',').join(' • ')}
              </p>
              <button
                onClick={() => { setSelectedHall(hall); setError(''); setAlternatives([]); setSuccess(''); }}
                className="btn-primary"
                style={{ width: '100%', padding: '0.9rem' }}
              >
                Reserve for Class
              </button>
            </div>
          ))}
        </div>

        {selectedHall && (
          <div style={{ position: 'fixed', inset: 0, backgroundColor: 'rgba(15,23,42,0.65)', backdropFilter: 'blur(6px)', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '1rem', zIndex: 50 }}>
            <div className="card" style={{ width: '100%', maxWidth: '520px', maxHeight: '90vh', overflowY: 'auto', padding: '2.5rem', borderTop: '6px solid var(--accent-orange)' }}>
              <h3 style={{ fontSize: '1.5rem', fontWeight: '800', marginBottom: '1.5rem', color: 'var(--primary-blue)' }}>Reserve {selectedHall.name}</h3>

              {success ? (
                <div style={{ backgroundColor: '#d1fae5', color: '#065f46', padding: '1.5rem', borderRadius: '8px', textAlign: 'center', fontWeight: '700' }}>✓ {success}</div>
              ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
                  {error && (
                    <div style={{ backgroundColor: '#fee2e2', color: '#b91c1c', padding: '1rem', borderRadius: '8px', borderLeft: '4px solid #ef4444' }}>
                      <p style={{ fontWeight: '700', marginBottom: alternatives.length ? '0.75rem' : 0 }}>{error}</p>
                      {alternatives.length > 0 && (
                        <ul style={{ paddingLeft: '1.5rem' }}>
                          {alternatives.map(a => <li key={a.id}><strong>{a.name}</strong> ({a.capacity} seats)</li>)}
                        </ul>
                      )}
                    </div>
                  )}
                  <div>
                    <label style={{ display: 'block', fontWeight: '600', marginBottom: '0.5rem', fontSize: '0.9rem' }}>Course</label>
                    <select value={selectedCourseId} onChange={e => setSelectedCourseId(e.target.value)} className="input-field">
                      <option value="">Select a course</option>
                      {initialCourses.map(c => <option key={c.id} value={c.id}>{c.code} - {c.name}</option>)}
                    </select>
                  </div>
                  <div>
                    <label style={{ display: 'block', fontWeight: '600', marginBottom: '0.5rem', fontSize: '0.9rem' }}>Date</label>
                    <input type="date" value={date} onChange={e => setDate(e.target.value)} className="input-field" />
                  </div>
                  <div style={{ display: 'flex', gap: '1rem' }}>
                    <div style={{ flex: 1 }}>
                      <label style={{ display: 'block', fontWeight: '600', marginBottom: '0.5rem', fontSize: '0.9rem' }}>Start</label>
                      <input type="time" value={startTime} onChange={e => setStartTime(e.target.value)} className="input-field" />
                    </div>
                    <div style={{ flex: 1 }}>
                      <label style={{ display: 'block', fontWeight: '600', marginBottom: '0.5rem', fontSize: '0.9rem' }}>End</label>
                      <input type="time" value={endTime} onChange={e => setEndTime(e.target.value)} className="input-field" />
                    </div>
                  </div>
                  <div style={{ display: 'flex', gap: '1rem', marginTop: '0.5rem' }}>
                    <button onClick={() => handleReserve(false)} disabled={loading} className="btn-primary" style={{ flex: 1, padding: '1rem' }}>
                      {loading ? 'Processing...' : 'Confirm Booking'}
                    </button>
                    {alternatives.length > 0 && (
                      <button onClick={() => handleReserve(true)} disabled={loading} style={{ flex: 1, padding: '1rem', backgroundColor: '#ef4444', color: 'white', border: 'none', borderRadius: '8px', cursor: 'pointer', fontWeight: '600' }}>
                        Book Anyway
                      </button>
                    )}
                    <button onClick={() => setSelectedHall(null)} className="btn-secondary" style={{ flex: 1, padding: '1rem' }}>Cancel</button>
                  </div>
                </div>
              )}
            </div>
          </div>
        )}
      </div>
    );
  }

  // --- DASHBOARD TAB ---
  const today = new Date().toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' });
  return (
    <div style={{ paddingBottom: '2rem' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1.5rem' }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '0.25rem' }}>
            <h2 style={{ fontSize: '1.75rem', fontWeight: '800', color: 'var(--text-primary)' }}>Hi, {session.name.split(' ')[0]}</h2>
            <span style={{ background: 'var(--accent-orange)', color: 'white', borderRadius: '999px', fontSize: '0.72rem', fontWeight: '700', padding: '0.2rem 0.6rem' }}>CLASS REP</span>
          </div>
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>{today}</p>
        </div>
        <div style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
          <NotificationBell />
          <ProfileAvatar session={session} />
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '1rem', marginBottom: '2rem' }}>
        <div className="card" style={{ background: 'var(--primary-blue)', color: 'white', padding: '1.5rem' }}>
          <p style={{ fontSize: '0.85rem', opacity: 0.85, marginBottom: '0.35rem' }}>Available halls</p>
          <h3 style={{ fontSize: '2rem', fontWeight: '800' }}>{initialHalls.length}</h3>
        </div>
        <div className="card" style={{ background: 'var(--accent-orange)', color: 'white', padding: '1.5rem' }}>
          <p style={{ fontSize: '0.85rem', opacity: 0.85, marginBottom: '0.35rem' }}>Courses on campus</p>
          <h3 style={{ fontSize: '2rem', fontWeight: '800' }}>{initialCourses.length}</h3>
        </div>
      </div>

      <h3 style={{ fontWeight: '700', marginBottom: '1rem' }}>Quick access</h3>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
        {initialHalls.slice(0, 4).map(hall => (
          <div key={hall.id} className="card border-left-blue" style={{ padding: '1rem' }}>
            <h4 style={{ fontWeight: '700', fontSize: '1rem' }}>{hall.name}</h4>
            <p style={{ color: 'var(--text-secondary)', fontSize: '0.82rem' }}>{hall.building_block} • {hall.capacity} seats</p>
          </div>
        ))}
      </div>
    </div>
  );
}
