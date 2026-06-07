import { PrismaClient } from '@prisma/client';
import { getSession, corsHeaders } from '../../../lib/auth';
import ReservationService from '../../../lib/services/ReservationService';

const prisma = new PrismaClient();
const reservationService = new ReservationService();

export async function OPTIONS() {
  return new Response(null, { status: 204, headers: corsHeaders });
}

export async function POST(request) {
  try {
    const session = await getSession(request);
    if (!session) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: corsHeaders });

    const data = await request.json();
    data.reserved_by = session.id;

    try {
      const reservation = await reservationService.bookRoom(data);
      return new Response(JSON.stringify({ success: true, reservation }), { status: 201, headers: corsHeaders });
    } catch (error) {
      if (error.message === 'CAPACITY_WARNING') {
        return new Response(JSON.stringify({
          error: 'CAPACITY_WARNING',
          message: error.details.message,
          alternatives: error.details.alternatives
        }), { status: 409, headers: corsHeaders });
      }
      return new Response(JSON.stringify({ error: error.message }), { status: 400, headers: corsHeaders });
    }

  } catch (error) {
    console.error('Reservation API error:', error);
    return new Response(JSON.stringify({ error: 'Internal Server Error' }), { status: 500, headers: corsHeaders });
  }
}

export async function GET(request) {
  try {
    const session = await getSession(request);
    if (!session) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: corsHeaders });

    const where = session.role === 'LECTURER'
      ? { reserved_by: session.id }
      : session.role === 'STUDENT' || session.role === 'PREFECT'
        ? { reserved_by: session.id }
        : undefined; // ADMIN sees all

    const reservations = await prisma.reservation.findMany({
      where,
      include: { hall: true, course: true, user: true }
    });
    return new Response(JSON.stringify(reservations), { status: 200, headers: corsHeaders });
  } catch (error) {
    return new Response(JSON.stringify({ error: 'Failed to fetch reservations' }), { status: 500, headers: corsHeaders });
  }
}
