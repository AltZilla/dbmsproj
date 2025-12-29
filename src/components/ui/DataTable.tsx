import { ReactNode } from 'react';

export interface Column<T> {
    header: string;
    accessor: keyof T | ((row: T) => ReactNode);
    className?: string;
}

interface DataTableProps<T> {
    columns: Column<T>[];
    data: T[];
    keyField?: keyof T;
    emptyMessage?: string;
}

/**
 * Generic DataTable component using the project's global CSS system.
 */
export function DataTable<T extends Record<string, any>>({
    columns,
    data,
    keyField = 'id',
    emptyMessage = 'No data available'
}: DataTableProps<T>) {
    return (
        <div className="table-container">
            <table className="table">
                <thead>
                    <tr>
                        {columns.map((col, index) => (
                            <th
                                key={index}
                                className={col.className}
                            >
                                {col.header}
                            </th>
                        ))}
                    </tr>
                </thead>
                <tbody>
                    {data.length === 0 ? (
                        <tr>
                            <td
                                colSpan={columns.length}
                                className="empty-state"
                            >
                                {emptyMessage}
                            </td>
                        </tr>
                    ) : (
                        data.map((row, rowIndex) => (
                            <tr
                                key={String(row[keyField]) || rowIndex}
                            >
                                {columns.map((col, colIndex) => (
                                    <td
                                        key={colIndex}
                                        className={col.className}
                                    >
                                        {typeof col.accessor === 'function'
                                            ? col.accessor(row)
                                            : row[col.accessor] as ReactNode}
                                    </td>
                                ))}
                            </tr>
                        ))
                    )}
                </tbody>
            </table>
        </div>
    );
}
