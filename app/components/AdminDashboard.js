'use client';

import { useState, useEffect } from 'react';

const DAYS = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

export default function AdminDashboard({ session, initialHalls, initialCourses, initialUsers, activeTab }) {
  const [halls, setHalls] = useState(initialHalls);
  const [courses, setCourses] = useState(initialCourses);
  const [users, setUsers] = useState(initialUsers || []);

  // Hall form
  const [hallName, setHallName] = useState('');
  const [hallCapacity, setHallCapacity] = useState('');
  const [hallFeatures, setHallFeatures] = useState('');
  const [hallBlock, setHallBlock] = useState('');
  const [editingHallId, setEditingHallId] = useState(null);
  const [editCapacity, setEditCapacity] = useState('');

  // Course form
  const [courseCode, setCourseCode] = useState('');
  const [courseName, setCourseName] = useState('');
  const [courseEnrolled, setCourseEnrolled] = useState('');
  const [courseLecturerId, setCourseLecturerId] = useState('');

  // Timetable
  const [timetable, setTimetable] = useState([]);
  const [ttHallId, setTtHallId] = useState('');
  const [ttCourseId, setTtCourseId] = useState('');
  const [ttDay, setTtDay] = useState('');
  const [ttStart, setTtStart] = useState('');
  const [ttEnd, setTtEnd] = useState('');
  const [loadingTt, setLoadingTt] = useState(false);

  const [loading, setLoading] = useState(false);
  const [updatingUserId, setUpdatingUserId] = useState(null);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const showMsg = (type, msg) => {
    if (type === 'error') { setError(msg); setSuccess(''); }
    else { setSuccess(msg); setError(''); }
    setTimeout(() => { setError(''); setSuccess(''); }, 4000);
  };

  useEffect(() => {
    if (activeTab === 'timetable') {
      setLoadingTt(true);
      fetch('/api/admin/timetable')
        .then(r => r.json())
        .then(data => { if (Array.isArray(data)) setTimetable(data); })
        .finally(() => setLoadingTt(false));
    }
  }, [activeTab]);

  const handleUpdateRole = async (userId, newRole) => {
    setUpdatingUserId(userId);
    try {
      const res = await fetch(`/api/admin/users/${userId}/role`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ role: newRole })
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error);
      setUsers(users.map(u => u.id === userId ? { ...u, role: newRole } : u));
      showMsg('success', 'User role updated!');
    } catch (err) {
      showMsg('error', err.message || 'Failed to update role');
    } finally {
      setUpdatingUserId(null);
    }
  };

  const handleUpdateCapacity = async (hallId) => {
    setLoading(true);
    try {
      const res = await fetch('/api/admin/halls', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: hallId, capacity: parseInt(editCapacity) })
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error);
      setHalls(halls.map(h => h.id === hallId ? { ...h, capacity: data.capacity } : h));
      showMsg('success', 'Capacity updated!');
      setEditingHallId(null);
    } catch (err) {
      showMsg('error', err.message || 'Failed to update capacity');
    } finally {
      setLoading(false);
    }
  };

  const handleAddHall = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      const res = await fetch('/api/admin/halls', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: hallName, capacity: parseInt(hallCapacity), features: hallFeatures, building_block: hallBlock })
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error);
      setHalls([...halls, data]);
      showMsg('success', 'Space added!');
      setHallName(''); setHallCapacity(''); setHallFeatures(''); setHallBlock('');
    } catch (err) {
      showMsg('error', err.message || 'Failed to add hall');
    } finally {
      setLoading(false);
    }
  };

  const handleAddCourse = async (e) => {
    e.preventDefault();
    if (!courseLecturerId) { showMsg('error', 'Please select a lecturer'); return; }
    setLoading(true);
    try {
      const res = await fetch('/api/admin/courses', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ code: courseCode, name: courseName, enrolled_count: parseInt(courseEnrolled), lecturer_id: courseLecturerId })
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error);
      setCourses([...courses, data]);
      showMsg('success', 'Course added!');
      setCourseCode(''); setCourseName(''); setCourseEnrolled(''); setCourseLecturerId('');
    } catch (err) {
      showMsg('error', err.message || 'Failed to add course');
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteCourse = async (courseId) => {
    if (!confirm('Delete this course and all its timetable/reservation data?')) return;
    setLoading(true);
    try {
      const res = await fetch(`/api/admin/courses?id=${courseId}`, { method: 'DELETE' });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error);
      setCourses(courses.filter(c => c.id !== courseId));
      showMsg('success', 'Course deleted!');
    } catch (err) {
      showMsg('error', err.message || 'Failed to delete course');
    } finally {
      setLoading(false);
    }
  };

  const handleAddTimetableEntry = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      const res = await fetch('/api/admin/timetable', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ hall_id: ttHallId, course_id: ttCourseId, day_of_week: ttDay, start_time: ttStart, end_time: ttEnd })
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error);
      setTimetable([...timetable, data]);
      showMsg('success', 'Timetable entry added!');
      setTtHallId(''); setTtCourseId(''); setTtDay(''); setTtStart(''); setTtEnd('');
    } catch (err) {
      showMsg('error', err.message || 'Failed to add entry');
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteTimetableEntry = async (id) => {
    if (!confirm('Remove this timetable entry?')) return;
    try {
      const res = await fetch('/api/admin/timetable', {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id })
      });
      if (!res.ok) throw new Error('Delete failed');
      setTimetable(timetable.filter(e => e.id !== id));
      showMsg('success', 'Entry removed!');
    } catch (err) {
      showMsg('error', err.message);
    }
  };

  const inputStyle = { display: 'block', fontWeight: '600', marginBottom: '0.5rem', color: 'var(--text-primary)' };

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
        <h2 style={{ fontSize: '2.25rem', fontWeight: '800', color: 'var(--primary-blue)', letterSpacing: '-0.025em' }}>Admin Dashboard</h2>
      </div>

      {error && <div style={{ backgroundColor: '#fee2e2', color: '#b91c1c', padding: '1rem', borderRadius: '8px', marginBottom: '1.5rem', fontWeight: '600' }}>{error}</div>}
      {success && <div style={{ backgroundColor: '#d1fae5', color: '#065f46', padding: '1rem', borderRadius: '8px', marginBottom: '1.5rem', fontWeight: '600' }}>✓ {success}</div>}

      {/* ── HALLS TAB ── */}
      {activeTab === 'halls' && (
        <div style={{ display: 'flex', gap: '2rem', alignItems: 'flex-start', flexWrap: 'wrap' }}>
          <div className="card" style={{ flex: 1, minWidth: '300px' }}>
            <h3 style={{ fontSize: '1.5rem', fontWeight: '800', marginBottom: '1.5rem', color: 'var(--primary-blue)' }}>Add New Space</h3>
            <form onSubmit={handleAddHall} style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
              <div><label style={inputStyle}>Space Name</label><input type="text" required value={hallName} onChange={e => setHallName(e.target.value)} className="input-field" placeholder="e.g. Auditorium C" /></div>
              <div><label style={inputStyle}>Capacity</label><input type="number" required value={hallCapacity} onChange={e => setHallCapacity(e.target.value)} className="input-field" placeholder="200" /></div>
              <div><label style={inputStyle}>Features (comma separated)</label><input type="text" required value={hallFeatures} onChange={e => setHallFeatures(e.target.value)} className="input-field" placeholder="projector, whiteboard, AC" /></div>
              <div><label style={inputStyle}>Building Block</label><input type="text" required value={hallBlock} onChange={e => setHallBlock(e.target.value)} className="input-field" placeholder="Main Block" /></div>
              <button type="submit" disabled={loading} className="btn-primary" style={{ padding: '1rem', fontSize: '1.05rem' }}>
                {loading ? 'Adding...' : 'Save Space'}
              </button>
            </form>
          </div>

          <div style={{ flex: 2, minWidth: '350px', display: 'grid', gap: '1rem' }}>
            <h3 style={{ fontSize: '1.5rem', fontWeight: '800', marginBottom: '0.5rem', color: 'var(--primary-blue)' }}>Existing Spaces ({halls.length})</h3>
            {halls.map(hall => (
              <div key={hall.id} className="card" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '1.25rem' }}>
                <div>
                  <h4 style={{ fontSize: '1.15rem', fontWeight: '700', marginBottom: '0.25rem' }}>{hall.name}</h4>
                  <p style={{ color: 'var(--text-secondary)', fontSize: '0.85rem' }}>{hall.building_block} • {hall.features.split(',').join(', ')}</p>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                  {editingHallId === hall.id ? (
                    <div style={{ display: 'flex', gap: '0.5rem' }}>
                      <input type="number" value={editCapacity} onChange={e => setEditCapacity(e.target.value)} style={{ width: '80px', padding: '0.4rem', borderRadius: '4px', border: '1px solid var(--border-color)', background: 'var(--surface-color)', color: 'var(--text-primary)' }} autoFocus />
                      <button onClick={() => handleUpdateCapacity(hall.id)} style={{ background: 'var(--primary-blue)', color: 'white', border: 'none', padding: '0.4rem 0.8rem', borderRadius: '4px', cursor: 'pointer' }}>Save</button>
                      <button onClick={() => setEditingHallId(null)} style={{ background: 'transparent', color: 'var(--text-muted)', border: 'none', cursor: 'pointer' }}>✕</button>
                    </div>
                  ) : (
                    <>
                      <span className="badge badge-orange" style={{ padding: '0.4rem 0.8rem', fontSize: '0.85rem' }}>{hall.capacity} seats</span>
                      <button onClick={() => { setEditingHallId(hall.id); setEditCapacity(hall.capacity); }} style={{ background: 'transparent', border: '1px solid var(--border-color)', borderRadius: '4px', padding: '0.3rem 0.6rem', cursor: 'pointer', color: 'var(--text-secondary)' }} title="Edit Capacity">✏️</button>
                    </>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* ── COURSES TAB ── */}
      {activeTab === 'courses' && (
        <div style={{ display: 'flex', gap: '2rem', alignItems: 'flex-start', flexWrap: 'wrap' }}>
          <div className="card" style={{ flex: 1, minWidth: '300px' }}>
            <h3 style={{ fontSize: '1.5rem', fontWeight: '800', marginBottom: '1.5rem', color: 'var(--primary-blue)' }}>Add New Course</h3>
            <form onSubmit={handleAddCourse} style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
              <div><label style={inputStyle}>Course Code</label><input type="text" required value={courseCode} onChange={e => setCourseCode(e.target.value)} className="input-field" placeholder="CS202" /></div>
              <div><label style={inputStyle}>Course Name</label><input type="text" required value={courseName} onChange={e => setCourseName(e.target.value)} className="input-field" placeholder="Data Structures" /></div>
              <div><label style={inputStyle}>Enrolled Students</label><input type="number" required value={courseEnrolled} onChange={e => setCourseEnrolled(e.target.value)} className="input-field" placeholder="150" /></div>
              <div>
                <label style={inputStyle}>Lecturer</label>
                <select required value={courseLecturerId} onChange={e => setCourseLecturerId(e.target.value)} className="input-field">
                  <option value="">Select a Lecturer</option>
                  {users.filter(u => u.role === 'LECTURER' || u.role === 'ADMIN').map(u => (
                    <option key={u.id} value={u.id}>{u.name}</option>
                  ))}
                </select>
              </div>
              <button type="submit" disabled={loading} className="btn-primary" style={{ padding: '1rem', fontSize: '1.05rem' }}>
                {loading ? 'Adding...' : 'Save Course'}
              </button>
            </form>
          </div>

          <div style={{ flex: 2, minWidth: '350px', display: 'grid', gap: '1rem' }}>
            <h3 style={{ fontSize: '1.5rem', fontWeight: '800', marginBottom: '0.5rem', color: 'var(--primary-blue)' }}>Existing Courses ({courses.length})</h3>
            {courses.map(course => (
              <div key={course.id} className="card" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '1.25rem' }}>
                <div>
                  <h4 style={{ fontSize: '1.1rem', fontWeight: '700', marginBottom: '0.25rem' }}>{course.code} — {course.name}</h4>
                  {course.lecturer && <p style={{ color: 'var(--text-secondary)', fontSize: '0.85rem' }}>Lecturer: {course.lecturer.name}</p>}
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                  <span className="badge" style={{ backgroundColor: 'var(--text-primary)', padding: '0.4rem 0.8rem', fontSize: '0.85rem' }}>{course.enrolled_count} students</span>
                  <button onClick={() => handleDeleteCourse(course.id)} disabled={loading} style={{ background: 'rgba(239,68,68,0.1)', color: 'var(--error)', border: '1px solid rgba(239,68,68,0.3)', borderRadius: '4px', padding: '0.4rem', cursor: 'pointer', display: 'flex', alignItems: 'center' }} title="Delete">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 6h18M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/><line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/></svg>
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* ── TIMETABLE TAB ── */}
      {activeTab === 'timetable' && (
        <div style={{ display: 'flex', gap: '2rem', alignItems: 'flex-start', flexWrap: 'wrap' }}>
          <div className="card" style={{ flex: 1, minWidth: '300px' }}>
            <h3 style={{ fontSize: '1.5rem', fontWeight: '800', marginBottom: '1.5rem', color: 'var(--primary-blue)' }}>Add Timetable Entry</h3>
            <form onSubmit={handleAddTimetableEntry} style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
              <div>
                <label style={inputStyle}>Hall</label>
                <select required value={ttHallId} onChange={e => setTtHallId(e.target.value)} className="input-field">
                  <option value="">Select Hall</option>
                  {halls.map(h => <option key={h.id} value={h.id}>{h.name} ({h.capacity} seats)</option>)}
                </select>
              </div>
              <div>
                <label style={inputStyle}>Course</label>
                <select required value={ttCourseId} onChange={e => setTtCourseId(e.target.value)} className="input-field">
                  <option value="">Select Course</option>
                  {courses.map(c => <option key={c.id} value={c.id}>{c.code} - {c.name}</option>)}
                </select>
              </div>
              <div>
                <label style={inputStyle}>Day of Week</label>
                <select required value={ttDay} onChange={e => setTtDay(e.target.value)} className="input-field">
                  <option value="">Select Day</option>
                  {DAYS.map(d => <option key={d} value={d}>{d}</option>)}
                </select>
              </div>
              <div style={{ display: 'flex', gap: '1rem' }}>
                <div style={{ flex: 1 }}>
                  <label style={inputStyle}>Start Time</label>
                  <input type="time" required value={ttStart} onChange={e => setTtStart(e.target.value)} className="input-field" />
                </div>
                <div style={{ flex: 1 }}>
                  <label style={inputStyle}>End Time</label>
                  <input type="time" required value={ttEnd} onChange={e => setTtEnd(e.target.value)} className="input-field" />
                </div>
              </div>
              <button type="submit" disabled={loading} className="btn-primary" style={{ padding: '1rem', fontSize: '1.05rem' }}>
                {loading ? 'Adding...' : 'Add to Timetable'}
              </button>
            </form>
          </div>

          <div style={{ flex: 2, minWidth: '350px', display: 'grid', gap: '1rem' }}>
            <h3 style={{ fontSize: '1.5rem', fontWeight: '800', marginBottom: '0.5rem', color: 'var(--primary-blue)' }}>
              Scheduled Classes ({timetable.length})
            </h3>
            {loadingTt ? (
              <div className="card" style={{ textAlign: 'center', padding: '2rem' }}><p style={{ color: 'var(--text-muted)' }}>Loading timetable...</p></div>
            ) : timetable.length === 0 ? (
              <div className="card" style={{ textAlign: 'center', padding: '2rem' }}><p style={{ color: 'var(--text-muted)' }}>No timetable entries yet.</p></div>
            ) : (
              DAYS.map(day => {
                const dayEntries = timetable.filter(e => e.day_of_week === day);
                if (dayEntries.length === 0) return null;
                return (
                  <div key={day}>
                    <h4 style={{ fontWeight: '700', color: 'var(--text-secondary)', fontSize: '0.85rem', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '0.5rem' }}>{day}</h4>
                    {dayEntries.sort((a, b) => a.start_time.localeCompare(b.start_time)).map(entry => (
                      <div key={entry.id} className="card" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '1rem', marginBottom: '0.5rem' }}>
                        <div>
                          <h5 style={{ fontWeight: '700', marginBottom: '0.2rem' }}>{entry.course?.code} — {entry.course?.name}</h5>
                          <p style={{ color: 'var(--text-secondary)', fontSize: '0.82rem' }}>
                            {entry.hall?.name} • {entry.start_time} – {entry.end_time}
                          </p>
                          {entry.course?.lecturer && (
                            <p style={{ color: 'var(--text-muted)', fontSize: '0.78rem' }}>{entry.course.lecturer.name}</p>
                          )}
                        </div>
                        <button onClick={() => handleDeleteTimetableEntry(entry.id)} style={{ background: 'rgba(239,68,68,0.1)', color: 'var(--error)', border: '1px solid rgba(239,68,68,0.3)', borderRadius: '4px', padding: '0.4rem', cursor: 'pointer', display: 'flex', alignItems: 'center' }} title="Remove">
                          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 6h18M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>
                        </button>
                      </div>
                    ))}
                  </div>
                );
              })
            )}
          </div>
        </div>
      )}

      {/* ── USERS TAB ── */}
      {activeTab === 'users' && (
        <div style={{ display: 'grid', gap: '1rem' }}>
          <h3 style={{ fontSize: '1.5rem', fontWeight: '800', marginBottom: '0.5rem', color: 'var(--primary-blue)' }}>User Management ({users.length})</h3>
          <div className="card" style={{ padding: '1.25rem', overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
              <thead>
                <tr style={{ borderBottom: '1px solid var(--border-color)' }}>
                  {['Name', 'Email', 'Current Role', 'Change Role'].map(h => (
                    <th key={h} style={{ padding: '1rem', color: 'var(--text-secondary)', fontWeight: '600', fontSize: '0.85rem' }}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {users.map(user => (
                  <tr key={user.id} style={{ borderBottom: '1px solid var(--border-color)' }}>
                    <td style={{ padding: '1rem', fontWeight: '600' }}>{user.name}</td>
                    <td style={{ padding: '1rem', color: 'var(--text-secondary)', fontSize: '0.9rem' }}>{user.email}</td>
                    <td style={{ padding: '1rem' }}>
                      <span className="badge" style={{ backgroundColor: 'var(--surface-color)', border: '1px solid var(--border-color)', color: 'var(--text-primary)' }}>{user.role}</span>
                    </td>
                    <td style={{ padding: '1rem' }}>
                      {user.id !== session.id ? (
                        <select
                          disabled={updatingUserId === user.id}
                          value={user.role}
                          onChange={e => handleUpdateRole(user.id, e.target.value)}
                          className="input-field"
                          style={{ padding: '0.4rem 0.8rem', width: 'auto', background: 'var(--surface-color)' }}
                        >
                          <option value="STUDENT">Student</option>
                          <option value="PREFECT">Prefect</option>
                          <option value="LECTURER">Lecturer</option>
                          <option value="ADMIN">Admin</option>
                        </select>
                      ) : (
                        <span style={{ color: 'var(--text-muted)', fontSize: '0.9rem' }}>You</span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}
