/**
 * Database Connection Module
 * ==========================
 * This module provides a singleton PostgreSQL connection pool.
 * 
 * KEY DBMS CONCEPTS:
 * 1. CONNECTION POOLING: Instead of creating a new connection for each request,
 *    we reuse connections from a pool. This significantly improves performance.
 * 2. ENVIRONMENT VARIABLES: Database credentials are stored securely in .env
 * 3. PREPARED STATEMENTS: Using parameterized queries to prevent SQL injection
 */

import { Pool, PoolClient, QueryResult, QueryResultRow } from 'pg';

// Create a connection pool
// The pool manages multiple connections and reuses them efficiently
// Supports both DATABASE_URL (for cloud providers) and individual env vars (for local dev)
const pool = new Pool(
    process.env.DATABASE_URL
        ? {
            connectionString: process.env.DATABASE_URL,
            ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
            // Pool configuration for serverless environments
            max: 10,                    // Lower max for serverless (Vercel has connection limits)
            idleTimeoutMillis: 10000,   // Shorter idle timeout for serverless
            connectionTimeoutMillis: 5000, // Slightly longer timeout for cold starts
        }
        : {
            host: process.env.DB_HOST || 'localhost',
            port: parseInt(process.env.DB_PORT || '5432'),
            database: process.env.DB_NAME || 'hostel_management',
            user: process.env.DB_USER || 'postgres',
            password: process.env.DB_PASSWORD || 'password',
            // Pool configuration for local development
            max: 20,                    // Maximum number of connections in the pool
            idleTimeoutMillis: 30000,   // Close idle connections after 30 seconds
            connectionTimeoutMillis: 2000, // Return an error after 2s if no connection
        }
);

// Log pool errors (connection issues)
pool.on('error', (err: Error) => {
    console.error('Unexpected error on idle client', err);
});

/**
 * Execute a SQL query with parameterized values
 * 
 * WHY PARAMETERIZED QUERIES?
 * - Prevents SQL injection attacks
 * - Allows PostgreSQL to cache query plans for better performance
 * 
 * @param text - SQL query string with $1, $2, etc. placeholders
 * @param params - Array of values to substitute into placeholders
 * @returns Query result with rows and metadata
 * 
 * @example
 * // Safe: Uses parameterized query
 * const result = await query('SELECT * FROM students WHERE id = $1', [studentId]);
 * 
 * // UNSAFE: Never concatenate user input directly!
 * // const result = await query(`SELECT * FROM students WHERE id = ${studentId}`);
 */
export async function query<T extends QueryResultRow = QueryResultRow>(
    text: string,
    params?: (string | number | boolean | null | Date)[]
): Promise<QueryResult<T>> {
    const start = Date.now();
    try {
        const result = await pool.query<T>(text, params);
        const duration = Date.now() - start;

        // Log query execution time in development
        if (process.env.NODE_ENV === 'development') {
            console.log('Executed query', { text: text.substring(0, 100), duration, rows: result.rowCount });
        }

        return result;
    } catch (error) {
        console.error('Database query error:', error);
        throw error;
    }
}

/**
 * Get a client from the pool for transaction support
 * 
 * TRANSACTIONS are essential for maintaining data integrity when
 * multiple operations need to succeed or fail together.
 * 
 * @example
 * const client = await getClient();
 * try {
 *   await client.query('BEGIN');
 *   await client.query('INSERT INTO students...');
 *   await client.query('INSERT INTO allocations...');
 *   await client.query('COMMIT');
 * } catch (e) {
 *   await client.query('ROLLBACK');
 *   throw e;
 * } finally {
 *   client.release();
 * }
 */
export async function getClient(): Promise<PoolClient> {
    const client = await pool.connect();
    return client;
}

/**
 * Execute multiple queries in a transaction
 * 
 * This helper function wraps multiple queries in BEGIN/COMMIT/ROLLBACK
 * to ensure atomicity - either all queries succeed or none do.
 * 
 * @param queries - Array of { text, params } query objects
 * @returns Array of query results
 */
export async function transaction<T extends QueryResultRow = QueryResultRow>(
    queries: Array<{ text: string; params?: (string | number | boolean | null | Date)[] }>
): Promise<QueryResult<T>[]> {
    const client = await pool.connect();
    const results: QueryResult<T>[] = [];

    try {
        // BEGIN transaction
        await client.query('BEGIN');

        // Execute all queries
        for (const q of queries) {
            const result = await client.query<T>(q.text, q.params);
            results.push(result);
        }

        // COMMIT if all succeeded
        await client.query('COMMIT');
        return results;
    } catch (error) {
        // ROLLBACK on any error
        await client.query('ROLLBACK');
        throw error;
    } finally {
        // Always release the client back to the pool
        client.release();
    }
}

/**
 * Close the pool (for graceful shutdown)
 */
export async function closePool(): Promise<void> {
    await pool.end();
}

// Export the pool for advanced use cases
export { pool };
