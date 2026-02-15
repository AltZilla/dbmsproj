import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

const allowedOrigins = ['*'];

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
    'Access-Control-Allow-Headers':
        'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version, Authorization',
    'Access-Control-Allow-Credentials': 'true',
    'Access-Control-Max-Age': '86400',
};

export function middleware(request: NextRequest) {
    // Get the origin from the request
    const origin = request.headers.get('origin') || '*';

    // Handle preflight OPTIONS request
    if (request.method === 'OPTIONS') {
        return new NextResponse(null, {
            status: 200,
            headers: {
                ...corsHeaders,
                'Access-Control-Allow-Origin': origin,
            },
        });
    }

    // For all other requests, add CORS headers to the response
    const response = NextResponse.next();
    Object.entries(corsHeaders).forEach(([key, value]) => {
        if (key === 'Access-Control-Allow-Origin') {
            response.headers.set(key, origin);
        } else {
            response.headers.set(key, value);
        }
    });

    return response;
}

// Only apply middleware to API routes
export const config = {
    matcher: '/api/:path*',
};
