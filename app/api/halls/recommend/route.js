import { PrismaClient } from '@prisma/client';
import ReservationService from '../../../../lib/services/ReservationService';

const reservationService = new ReservationService();

export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const course_id = searchParams.get('course_id');
    const date = searchParams.get('date');
    const start_time = searchParams.get('start_time');
    const end_time = searchParams.get('end_time');

    if (!course_id || !date || !start_time || !end_time) {
      return new Response(JSON.stringify({ error: 'Missing required parameters' }), { status: 400 });
    }

    const recommendations = await reservationService.getRecommendations(course_id, date, start_time, end_time);
    
    return new Response(JSON.stringify({ recommendations }), { status: 200 });
  } catch (error) {
    console.error('Recommendations API error:', error);
    return new Response(JSON.stringify({ error: 'Internal Server Error' }), { status: 500 });
  }
}
