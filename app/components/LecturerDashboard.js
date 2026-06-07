'use client';

import { useState } from 'react';

export default function LecturerDashboard({ session, initialHalls, initialCourses, activeTab }) {
  const [selectedHall, setSelectedHall] = useState(null);
  const [date, setDate] = useState('');
  const [startTime, setStartTime] = useState('');
  const [endTime, setEndTime] = useState('');
  const [selectedCourseId, setSelectedCourseId] = useState('');
  const [bookingKey, setBookingKey] = useState('');
  
  
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [alternatives, setAlternatives] = useState([]);
  const [success, setSuccess] = useState('');

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
          date,
          start_time: startTime,
          end_time: endTime,
          course_id: selectedCourseId,
          hall_id: selectedHall.id,
          force_booking,
          booking_key: bookingKey
        })
      });

      const data = await res.json();

      if (res.status === 409) {
        setError(data.message);
        setAlternatives(data.alternatives || []);
      } else if (!res.ok) {
        setError(data.error || 'Failed to reserve');
      } else {
        setSuccess('Reservation successful!');
        setTimeout(() => {
          setSelectedHall(null);
          setSuccess('');
        }, 2000);
      }
    } catch (err) {
      setError('An unexpected error occurred');
    } finally {
      setLoading(false);
    }
  };

  if (activeTab === 'courses') {
    const myCourses = initialCourses.filter(course => course.lecturer_id === session.id);
    return (
      <div>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
          <h2 style={{ fontSize: '2.25rem', fontWeight: '800', color: 'var(--primary-blue)', letterSpacing: '-0.025em' }}>My Courses</h2>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: '2rem' }}>
          {myCourses.length === 0 ? (
            <p style={{ color: 'var(--text-secondary)' }}>You have no assigned courses.</p>
          ) : (
            myCourses.map(course => (
              <div key={course.id} className="card" style={{ padding: '1.5rem', borderLeft: '4px solid var(--primary-blue)' }}>
                <h3 style={{ fontSize: '1.25rem', fontWeight: '700', marginBottom: '0.5rem' }}>{course.code} - {course.name}</h3>
                <p style={{ color: 'var(--text-secondary)' }}>Enrolled Students: {course.enrolled_count}</p>
              </div>
            ))
          )}
        </div>
      </div>
    );
  }

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
        <h2 style={{ fontSize: '2.25rem', fontWeight: '800', color: 'var(--primary-blue)', letterSpacing: '-0.025em' }}>Available Spaces</h2>
        <span style={{ color: 'var(--text-secondary)', fontWeight: '500' }}>Select a hall to reserve for your class</span>
      </div>
      
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: '2rem' }}>
        {initialHalls.map(hall => (
          <div key={hall.id} className="card" style={{ display: 'flex', flexDirection: 'column' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1rem' }}>
              <h3 style={{ fontSize: '1.5rem', fontWeight: '700', color: 'var(--text-primary)' }}>{hall.name}</h3>
              <span className="badge badge-orange" style={{ padding: '0.4rem 0.8rem', fontSize: '0.85rem' }}>{hall.capacity} seats</span>
            </div>
            <p style={{ color: 'var(--text-secondary)', fontSize: '0.95rem', marginBottom: '2rem', flex: 1, lineHeight: 1.5 }}>
              {hall.features.split(',').join(' • ')}
            </p>
            <button 
              onClick={() => { setSelectedHall(hall); setError(''); setAlternatives([]); setSuccess(''); }}
              className="btn-primary"
              style={{ width: '100%', fontSize: '1.05rem', padding: '1rem' }}
            >
              Reserve Space
            </button>
          </div>
        ))}
      </div>

      {selectedHall && (
        <div style={{ position: 'fixed', inset: 0, backgroundColor: 'rgba(15, 23, 42, 0.65)', backdropFilter: 'blur(6px)', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '1rem', zIndex: 50 }}>
          <div className="card" style={{ width: '100%', maxWidth: '550px', maxHeight: '90vh', overflowY: 'auto', padding: '2.5rem', borderTop: '6px solid var(--primary-blue)' }}>
            <h3 style={{ fontSize: '1.75rem', fontWeight: '800', marginBottom: '1.5rem', color: 'var(--primary-blue)', letterSpacing: '-0.025em' }}>Reserve {selectedHall.name}</h3>
            
            {success ? (
              <div style={{ backgroundColor: '#d1fae5', color: '#065f46', padding: '1.5rem', borderRadius: '8px', textAlign: 'center', fontWeight: '600', fontSize: '1.1rem' }}>
                ✓ {success}
              </div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
                {error && (
                  <div style={{ backgroundColor: '#fee2e2', color: '#b91c1c', padding: '1.25rem', borderRadius: '8px', fontSize: '0.9rem', borderLeft: '4px solid #ef4444' }}>
                    <p style={{ fontWeight: '700', marginBottom: '0.75rem', fontSize: '1rem' }}>{error}</p>
                    {alternatives.length > 0 && (
                      <div style={{ marginTop: '0.5rem' }}>
                        <p style={{ marginBottom: '0.5rem', fontWeight: '500' }}>Try these available alternatives instead:</p>
                        <ul style={{ paddingLeft: '1.5rem', display: 'flex', flexDirection: 'column', gap: '0.25rem' }}>
                          {alternatives.map(alt => (
                            <li key={alt.id}><strong>{alt.name}</strong> ({alt.capacity} seats)</li>
                          ))}
                        </ul>
                      </div>
                    )}
                  </div>
                )}

                <div>
                  <label style={{ display: 'block', fontSize: '0.9rem', fontWeight: '600', marginBottom: '0.5rem', color: 'var(--text-primary)' }}>Course</label>
                  <select 
                    value={selectedCourseId} 
                    onChange={e => setSelectedCourseId(e.target.value)}
                    className="input-field"
                  >
                    <option value="">Select a course</option>
                    {initialCourses.map(course => (
                      <option key={course.id} value={course.id}>{course.code} - {course.name} ({course.enrolled_count} students)</option>
                    ))}
                  </select>
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '0.9rem', fontWeight: '600', marginBottom: '0.5rem', color: 'var(--text-primary)' }}>Date</label>
                  <input type="date" value={date} onChange={e => setDate(e.target.value)} className="input-field" />
                </div>

                <div style={{ display: 'flex', gap: '1.25rem' }}>
                  <div style={{ flex: 1 }}>
                    <label style={{ display: 'block', fontSize: '0.9rem', fontWeight: '600', marginBottom: '0.5rem', color: 'var(--text-primary)' }}>Start Time</label>
                    <input type="time" value={startTime} onChange={e => setStartTime(e.target.value)} className="input-field" />
                  </div>
                  <div style={{ flex: 1 }}>
                    <label style={{ display: 'block', fontSize: '0.9rem', fontWeight: '600', marginBottom: '0.5rem', color: 'var(--text-primary)' }}>End Time</label>
                    <input type="time" value={endTime} onChange={e => setEndTime(e.target.value)} className="input-field" />
                  </div>
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '0.9rem', fontWeight: '600', marginBottom: '0.5rem', color: 'var(--text-primary)' }}>Booking Key / PIN</label>
                  <input type="password" placeholder="Enter or create your unique booking key" value={bookingKey} onChange={e => setBookingKey(e.target.value)} className="input-field" />
                  <p style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', marginTop: '0.25rem' }}>If you haven't set one, the key you enter now will be saved to your profile.</p>
                </div>

                <div style={{ display: 'flex', gap: '1rem', marginTop: '1.5rem' }}>
                  <button 
                    onClick={() => handleReserve(false)} 
                    disabled={loading}
                    className="btn-primary"
                    style={{ flex: 1, padding: '1rem', fontSize: '1rem' }}
                  >
                    {loading ? 'Processing...' : 'Confirm Booking'}
                  </button>
                  
                  {alternatives.length > 0 && (
                    <button 
                      onClick={() => handleReserve(true)} 
                      disabled={loading}
                      style={{ flex: 1, padding: '1rem', backgroundColor: '#ef4444', color: 'white', border: 'none', borderRadius: '8px', cursor: 'pointer', fontWeight: '600', transition: 'background-color 0.2s' }}
                    >
                      Book Anyway
                    </button>
                  )}

                  <button 
                    onClick={() => setSelectedHall(null)} 
                    className="btn-secondary"
                    style={{ flex: 1, padding: '1rem', fontSize: '1rem' }}
                  >
                    Cancel
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
