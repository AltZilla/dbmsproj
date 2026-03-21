export const ANALYTICS_RANGE_CONFIG = {
    '1w': {
        label: '1 Week',
        description: 'Last 7 days',
        interval: '7 days',
        bucket: 'day',
    },
    '1m': {
        label: '1 Month',
        description: 'Last 30 days',
        interval: '1 month',
        bucket: 'day',
    },
    '3m': {
        label: '3 Months',
        description: 'Last 3 months',
        interval: '3 months',
        bucket: 'week',
    },
    '6m': {
        label: '6 Months',
        description: 'Last 6 months',
        interval: '6 months',
        bucket: 'month',
    },
    '1y': {
        label: '1 Year',
        description: 'Last 12 months',
        interval: '1 year',
        bucket: 'month',
    },
} as const;

export type AnalyticsRangeKey = keyof typeof ANALYTICS_RANGE_CONFIG;

const LEGACY_MONTH_TO_RANGE: Record<string, AnalyticsRangeKey> = {
    '1': '1m',
    '3': '3m',
    '6': '6m',
    '12': '1y',
};

const LEGACY_DAYS_TO_RANGE: Record<string, AnalyticsRangeKey> = {
    '7': '1w',
    '30': '1m',
    '90': '3m',
    '180': '6m',
    '365': '1y',
};

export function getAnalyticsRangeKey(
    params: URLSearchParams,
    fallback: AnalyticsRangeKey = '6m'
): AnalyticsRangeKey {
    const range = params.get('range');
    if (range && range in ANALYTICS_RANGE_CONFIG) {
        return range as AnalyticsRangeKey;
    }

    const months = params.get('months');
    if (months && months in LEGACY_MONTH_TO_RANGE) {
        return LEGACY_MONTH_TO_RANGE[months];
    }

    const days = params.get('days');
    if (days && days in LEGACY_DAYS_TO_RANGE) {
        return LEGACY_DAYS_TO_RANGE[days];
    }

    return fallback;
}

export function getAnalyticsRangeMeta(
    params: URLSearchParams,
    fallback: AnalyticsRangeKey = '6m'
) {
    const key = getAnalyticsRangeKey(params, fallback);
    return {
        key,
        ...ANALYTICS_RANGE_CONFIG[key],
    };
}

export function getAnalyticsDateFilter(column: string, interval: string) {
    return `${column} >= NOW() - INTERVAL '${interval}'`;
}
