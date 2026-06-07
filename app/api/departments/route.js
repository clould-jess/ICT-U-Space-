import { corsHeaders } from '../../../lib/auth';

export async function OPTIONS() {
  return new Response(null, { status: 204, headers: corsHeaders });
}

export async function GET() {
  // In the future, this can be fetched from a Department model in Prisma.
  // For now, we serve a static list from the backend to decouple it from the Flutter app.
  const departments = {
    'ICT': 'Information and Communication Technology',
    'ACC': 'Accounting',
    'BMS': 'Business Management',
    'ENG': 'Engineering',
    'LAW': 'Law',
    'MED': 'Medicine',
  };

  return new Response(JSON.stringify(departments), {
    status: 200,
    headers: corsHeaders,
  });
}
