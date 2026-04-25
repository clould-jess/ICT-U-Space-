import { PrismaClient } from '@prisma/client';
import { cookies } from 'next/headers';
import ReservationService from '../../../lib/services/ReservationService';

const prisma = new PrismaClient();
const reservationService = new ReservationService();

export async function POST(request) {
  try {
    const sessionCookie = (await cookies()).get('session');
    if (!sessionCookie) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 });
    const session = JSON.parse(sessionCookie.value);

    const data = await request.json();
    data.reserved_by = session.id;

    try {
      // Abstraction: All business logic is handled by the OOP service
      const reservation = await reservationService.bookRoom(data);
      return new Response(JSON.stringify({ success: true, reservation }), { status: 201 });
    } catch (error) {
      if (error.message === 'CAPACITY_WARNING') {
        return new Response(JSON.stringify({ 
          error: 'CAPACITY_WARNING', 
          message: error.details.message,
          alternatives: error.details.alternatives 
        }), { status: 409 });
      }
      return new Response(JSON.stringify({ error: error.message }), { status: 400 });
    }

  } catch (error) {
    console.error('Reservation API error:', error);
    return new Response(JSON.stringify({ error: 'Internal Server Error' }), { status: 500 });
  }
}

export async function GET() {
  try {
    const reservations = await prisma.reservation.findMany({
      include: { hall: true, course: true, user: true }
    });
    return new Response(JSON.stringify(reservations), { status: 200 });
  } catch (error) {
    return new Response(JSON.stringify({ error: 'Failed to fetch reservations' }), { status: 500 });
  }
}
