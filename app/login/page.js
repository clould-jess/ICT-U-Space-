'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';

export default function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const router = useRouter();

  const handleLogin = async (e) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    try {
      const res = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      });

      if (res.ok) {
        router.push('/');
        router.refresh();
      } else {
        const data = await res.json();
        setError(data.error || 'Login failed');
      }
    } catch {
      setError('An unexpected error occurred');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div style={{ minHeight: '100vh', display: 'flex', backgroundColor: 'var(--bg-color)' }}>
      {/* Left side: branding/image */}
      <div style={{ flex: 1, background: 'linear-gradient(135deg, var(--primary-blue) 0%, var(--primary-blue-hover) 100%)', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', color: 'white', padding: '3rem' }}>
        <div style={{ width: '80px', height: '80px', borderRadius: '20px', background: 'var(--accent-orange)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 'bold', fontSize: '2.5rem', marginBottom: '2rem', boxShadow: '0 10px 25px rgba(251, 146, 60, 0.4)' }}>C</div>
        <h1 style={{ fontSize: '3.5rem', fontWeight: '800', marginBottom: '1.5rem', textAlign: 'center', letterSpacing: '-0.025em' }}>Campus Space</h1>
        <p style={{ fontSize: '1.25rem', textAlign: 'center', maxWidth: '400px', opacity: 0.9, lineHeight: 1.6 }}>
          Intelligent classroom reservations and real-time schedule management for your institution.
        </p>
      </div>

      {/* Right side: Login form */}
      <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '2rem' }}>
        <div className="card" style={{ width: '100%', maxWidth: '450px', padding: '3.5rem 3rem' }}>
          <h2 style={{ fontSize: '2rem', fontWeight: 'bold', marginBottom: '0.5rem', color: 'var(--primary-blue)' }}>Welcome Back</h2>
          <p style={{ color: 'var(--text-secondary)', marginBottom: '2.5rem' }}>Sign in to manage your spaces and schedule</p>

          {error && (
            <div style={{ backgroundColor: '#fee2e2', color: '#b91c1c', padding: '1rem', borderRadius: '8px', marginBottom: '1.5rem', fontSize: '0.875rem', fontWeight: '500', borderLeft: '4px solid #b91c1c' }}>
              {error}
            </div>
          )}

          <form onSubmit={handleLogin} style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
            <div>
              <label htmlFor="email" style={{ display: 'block', fontSize: '0.875rem', fontWeight: '600', color: 'var(--text-primary)', marginBottom: '0.5rem' }}>Email Address</label>
              <input
                id="email"
                type="email"
                className="input-field"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                placeholder="admin@school.edu"
              />
            </div>

            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.5rem' }}>
                <label htmlFor="password" style={{ fontSize: '0.875rem', fontWeight: '600', color: 'var(--text-primary)' }}>Password</label>
                <a href="#" style={{ color: 'var(--primary-blue)', textDecoration: 'none', fontWeight: '500', fontSize: '0.85rem' }}>Forgot password?</a>
              </div>
              <input
                id="password"
                type="password"
                className="input-field"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                placeholder="••••••••"
              />
            </div>
            
            <button
              type="submit"
              disabled={isLoading}
              className="btn-accent"
              style={{ marginTop: '1rem', width: '100%', padding: '1rem', fontSize: '1.125rem', boxShadow: '0 4px 14px 0 rgba(251, 146, 60, 0.39)' }}
            >
              {isLoading ? 'Signing in...' : 'Sign In'}
            </button>
          </form>

          <div style={{ marginTop: '3rem', fontSize: '0.875rem', textAlign: 'center', borderTop: '1px solid var(--border-color)', paddingTop: '2rem' }}>
            <p style={{ marginBottom: '1rem', fontWeight: '600', color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Quick Sign In Demo</p>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.75rem', justifyContent: 'center' }}>
              <span className="badge" style={{ cursor: 'pointer', backgroundColor: 'var(--bg-color)', color: 'var(--primary-blue)', border: '1px solid var(--primary-blue)', padding: '0.5rem 1rem' }} onClick={() => setEmail('admin@school.edu')}>Admin</span>
              <span className="badge" style={{ cursor: 'pointer', backgroundColor: 'var(--bg-color)', color: 'var(--primary-blue)', border: '1px solid var(--primary-blue)', padding: '0.5rem 1rem' }} onClick={() => setEmail('smith@school.edu')}>Lecturer</span>
              <span className="badge" style={{ cursor: 'pointer', backgroundColor: 'var(--bg-color)', color: 'var(--primary-blue)', border: '1px solid var(--primary-blue)', padding: '0.5rem 1rem' }} onClick={() => setEmail('peter@student.school.edu')}>Prefect</span>
              <span className="badge" style={{ cursor: 'pointer', backgroundColor: 'var(--bg-color)', color: 'var(--primary-blue)', border: '1px solid var(--primary-blue)', padding: '0.5rem 1rem' }} onClick={() => setEmail('sam@student.school.edu')}>Student</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
