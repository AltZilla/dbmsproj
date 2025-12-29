'use client';

import { useState, useEffect, Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import Link from 'next/link';

interface Payment {
    id: number;
    amount: string;
    due_date: string;
    payment_date: string | null;
    payment_status: 'pending' | 'paid' | 'overdue' | 'partial';
    receipt_number: string | null;
    semester: string | null;
    notes: string | null;
}

const statusConfig: Record<string, string> = {
    paid: 'bg-green-100 text-green-800 border-green-200',
    pending: 'bg-amber-100 text-amber-800 border-amber-200',
    overdue: 'bg-red-100 text-red-800 border-red-200',
    partial: 'bg-blue-100 text-blue-800 border-blue-200'
};

function StudentPaymentsContent() {
    const searchParams = useSearchParams();
    const studentId = parseInt(searchParams.get('id') || '1');

    const [loading, setLoading] = useState(true);
    const [payments, setPayments] = useState<Payment[]>([]);
    const [stats, setStats] = useState({ totalPaid: 0, totalPending: 0 });
    const [showPaymentModal, setShowPaymentModal] = useState(false);
    const [processingPayment, setProcessingPayment] = useState(false);
    const [paymentSuccess, setPaymentSuccess] = useState(false);

    const fetchPayments = async () => {
        try {
            const res = await fetch(`/api/payments?student_id=${studentId}&limit=50`);
            const data = await res.json();

            if (data.success) {
                const paymentList: Payment[] = data.data;
                setPayments(paymentList);

                // Calculate totals
                const paid = paymentList
                    .filter(p => p.payment_status === 'paid')
                    .reduce((sum, p) => sum + parseFloat(p.amount), 0);

                const pending = paymentList
                    .filter(p => ['pending', 'overdue', 'partial'].includes(p.payment_status))
                    .reduce((sum, p) => sum + parseFloat(p.amount), 0);

                setStats({ totalPaid: paid, totalPending: pending });
            }
        } catch (error) {
            console.error('Failed to fetch payments:', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchPayments();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [studentId]);

    const pendingPayments = payments.filter(p => ['pending', 'overdue', 'partial'].includes(p.payment_status));

    // State for selected payments (partial payment support)
    const [selectedPaymentIds, setSelectedPaymentIds] = useState<Set<number>>(new Set());

    // Calculate selected amount
    const selectedAmount = pendingPayments
        .filter(p => selectedPaymentIds.has(p.id))
        .reduce((sum, p) => sum + parseFloat(p.amount), 0);

    // Toggle payment selection
    const togglePaymentSelection = (paymentId: number) => {
        setSelectedPaymentIds(prev => {
            const newSet = new Set(prev);
            if (newSet.has(paymentId)) {
                newSet.delete(paymentId);
            } else {
                newSet.add(paymentId);
            }
            return newSet;
        });
    };

    // Select all pending payments
    const selectAllPayments = () => {
        setSelectedPaymentIds(new Set(pendingPayments.map(p => p.id)));
    };

    // Clear selection
    const clearSelection = () => {
        setSelectedPaymentIds(new Set());
    };

    // Initialize selection when modal opens
    useEffect(() => {
        if (showPaymentModal) {
            selectAllPayments();
        }
    }, [showPaymentModal, pendingPayments.length]);

    const handlePayNow = async () => {
        if (selectedPaymentIds.size === 0) {
            alert('Please select at least one payment to process.');
            return;
        }

        setProcessingPayment(true);

        try {
            // Process only selected payments
            const paymentsToProcess = pendingPayments.filter(p => selectedPaymentIds.has(p.id));

            for (const payment of paymentsToProcess) {
                await fetch(`/api/payments/${payment.id}`, {
                    method: 'PUT',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        payment_status: 'paid',
                        payment_date: new Date().toISOString().split('T')[0],
                        receipt_number: `RCP-${Date.now().toString().slice(-8)}`
                    })
                });
            }

            setPaymentSuccess(true);

            // Refresh payments after 2 seconds
            setTimeout(async () => {
                setShowPaymentModal(false);
                setPaymentSuccess(false);
                setSelectedPaymentIds(new Set());
                setLoading(true);
                await fetchPayments();
            }, 2000);

        } catch (error) {
            console.error('Payment failed:', error);
            alert('Payment failed. Please try again.');
        } finally {
            setProcessingPayment(false);
        }
    };


    if (loading) return <div className="min-h-[200px] flex items-center justify-center"><div className="animate-spin rounded-full h-10 w-10 border-4 border-indigo-200 border-t-indigo-600"></div></div>;

    return (
        <div className="max-w-7xl mx-auto px-6 py-8">
            <Link href={`/student?id=${studentId}`} className="inline-flex items-center text-gray-500 hover:text-indigo-600 mb-6 transition-colors font-medium">
                <span className="mr-2">←</span> Back to Dashboard
            </Link>
            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-8">
                <div>
                    <h1 className="text-3xl font-bold text-gray-900 mb-1">Payments & Dues</h1>
                    <p className="text-gray-500">Track your fee payments and outstanding dues</p>
                </div>
                {stats.totalPending > 0 && (
                    <button
                        onClick={() => setShowPaymentModal(true)}
                        className="bg-indigo-600 text-white px-6 py-2.5 rounded-lg text-sm font-medium hover:bg-indigo-700 transition-colors shadow-sm"
                    >
                        Pay Now
                    </button>
                )}
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
                <div className="bg-white rounded-xl p-6 shadow-sm border border-green-100 relative overflow-hidden">
                    <div className="text-sm font-medium text-gray-500 mb-1">Total Paid</div>
                    <div className="text-3xl font-bold text-green-600">
                        ₹{stats.totalPaid.toLocaleString()}
                    </div>
                </div>
                <div className={`bg-white rounded-xl p-6 shadow-sm border relative overflow-hidden ${stats.totalPending > 0 ? 'border-amber-100' : 'border-gray-100'}`}>
                    <div className="text-sm font-medium text-gray-500 mb-1">Total Pending</div>
                    <div className={`text-3xl font-bold ${stats.totalPending > 0 ? 'text-amber-600' : 'text-green-600'}`}>
                        ₹{stats.totalPending.toLocaleString()}
                    </div>
                </div>
            </div>

            <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
                <div className="overflow-x-auto">
                    <table className="w-full text-left border-collapse">
                        <thead>
                            <tr className="bg-gray-50/50 border-b border-gray-200 text-xs uppercase text-gray-500 font-medium">
                                <th className="px-6 py-4">Date / Due Date</th>
                                <th className="px-6 py-4">Description / Sem</th>
                                <th className="px-6 py-4">Amount</th>
                                <th className="px-6 py-4">Status</th>
                                <th className="px-6 py-4">Receipt</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-100">
                            {payments.length === 0 ? (
                                <tr>
                                    <td colSpan={5} className="px-6 py-12 text-center text-gray-500 italic">No current payment records found</td>
                                </tr>
                            ) : (
                                payments.map(payment => (
                                    <tr key={payment.id} className="hover:bg-gray-50/50 transition-colors">
                                        <td className="px-6 py-4">
                                            <div className="font-medium text-gray-900">
                                                {payment.payment_date
                                                    ? new Date(payment.payment_date).toLocaleDateString()
                                                    : new Date(payment.due_date).toLocaleDateString()
                                                }
                                            </div>
                                            <div className="text-xs text-gray-500 mt-0.5">
                                                {payment.payment_date ? 'Paid on' : 'Due by'}
                                            </div>
                                        </td>
                                        <td className="px-6 py-4">
                                            <div className="text-gray-900 font-medium">{payment.semester || 'Fee Payment'}</div>
                                            {payment.notes && <div className="text-xs text-gray-500 mt-0.5">{payment.notes}</div>}
                                        </td>
                                        <td className="px-6 py-4">
                                            <div className="font-bold text-gray-900">₹{parseFloat(payment.amount).toLocaleString()}</div>
                                        </td>
                                        <td className="px-6 py-4">
                                            <span className={`inline-flex px-2.5 py-1 rounded-full text-xs font-semibold capitalize border ${statusConfig[payment.payment_status] || 'bg-gray-100 text-gray-800'}`}>
                                                {payment.payment_status}
                                            </span>
                                        </td>
                                        <td className="px-6 py-4">
                                            <span className="font-mono text-xs text-gray-500 bg-gray-100 px-2 py-1 rounded">
                                                {payment.receipt_number || '-'}
                                            </span>
                                        </td>
                                    </tr>
                                ))
                            )}
                        </tbody>
                    </table>
                </div>
            </div>

            {/* Payment Modal */}
            {showPaymentModal && (
                <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
                    <div className="bg-white rounded-2xl shadow-2xl max-w-md w-full overflow-hidden">
                        <div className="bg-gradient-to-r from-indigo-600 to-purple-600 px-6 py-4">
                            <h2 className="text-xl font-bold text-white">
                                {paymentSuccess ? '✅ Payment Successful!' : 'Complete Payment'}
                            </h2>
                        </div>
                        <div className="p-6">
                            {paymentSuccess ? (
                                <div className="text-center py-8">
                                    <div className="text-6xl mb-4">🎉</div>
                                    <p className="text-lg text-gray-700 font-medium">Your payment has been processed successfully!</p>
                                    <p className="text-sm text-gray-500 mt-2">Redirecting...</p>
                                </div>
                            ) : (
                                <>
                                    <div className="bg-gradient-to-br from-indigo-50 to-purple-50 rounded-xl p-4 mb-6 border border-indigo-100">
                                        <div className="text-sm text-gray-500 mb-1">Selected Amount</div>
                                        <div className="text-3xl font-bold text-indigo-600">₹{selectedAmount.toLocaleString()}</div>
                                        <div className="text-xs text-gray-400 mt-1">
                                            {selectedPaymentIds.size} of {pendingPayments.length} items selected
                                        </div>
                                    </div>

                                    <div className="mb-4">
                                        <div className="flex justify-between items-center mb-3">
                                            <h3 className="text-sm font-medium text-gray-700">Select Payments:</h3>
                                            <div className="flex gap-2">
                                                <button
                                                    onClick={selectAllPayments}
                                                    className="text-xs text-indigo-600 hover:text-indigo-800 font-medium"
                                                >
                                                    Select All
                                                </button>
                                                <span className="text-gray-300">|</span>
                                                <button
                                                    onClick={clearSelection}
                                                    className="text-xs text-gray-500 hover:text-gray-700 font-medium"
                                                >
                                                    Clear
                                                </button>
                                            </div>
                                        </div>
                                        <div className="space-y-2 max-h-48 overflow-y-auto">
                                            {pendingPayments.map(p => (
                                                <label
                                                    key={p.id}
                                                    className={`flex items-center justify-between p-3 rounded-lg border cursor-pointer transition-all ${selectedPaymentIds.has(p.id)
                                                        ? 'bg-indigo-50 border-indigo-300'
                                                        : 'bg-white border-gray-200 hover:border-gray-300'
                                                        }`}
                                                >
                                                    <div className="flex items-center gap-3">
                                                        <input
                                                            type="checkbox"
                                                            checked={selectedPaymentIds.has(p.id)}
                                                            onChange={() => togglePaymentSelection(p.id)}
                                                            className="w-4 h-4 text-indigo-600 rounded border-gray-300 focus:ring-indigo-500"
                                                        />
                                                        <div>
                                                            <div className="text-sm font-medium text-gray-900">{p.semester || 'Fee Payment'}</div>
                                                            <div className="text-xs text-gray-500">Due: {new Date(p.due_date).toLocaleDateString()}</div>
                                                        </div>
                                                    </div>
                                                    <span className={`font-bold ${selectedPaymentIds.has(p.id) ? 'text-indigo-600' : 'text-gray-900'}`}>
                                                        ₹{parseFloat(p.amount).toLocaleString()}
                                                    </span>
                                                </label>
                                            ))}
                                        </div>
                                    </div>

                                    <div className="bg-amber-50 border border-amber-200 rounded-lg p-3 mb-6">
                                        <p className="text-xs text-amber-800">
                                            ⚠️ This is a demo payment. No actual transaction will occur.
                                        </p>
                                    </div>

                                    <div className="flex gap-3">
                                        <button
                                            onClick={() => setShowPaymentModal(false)}
                                            className="flex-1 px-4 py-2.5 border border-gray-300 rounded-lg text-gray-700 font-medium hover:bg-gray-50 transition-colors"
                                            disabled={processingPayment}
                                        >
                                            Cancel
                                        </button>
                                        <button
                                            onClick={handlePayNow}
                                            disabled={processingPayment || selectedPaymentIds.size === 0}
                                            className="flex-1 px-4 py-2.5 bg-indigo-600 text-white rounded-lg font-medium hover:bg-indigo-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                                        >
                                            {processingPayment ? (
                                                <>
                                                    <div className="animate-spin rounded-full h-4 w-4 border-2 border-white border-t-transparent"></div>
                                                    Processing...
                                                </>
                                            ) : (
                                                `Pay ₹${selectedAmount.toLocaleString()}`
                                            )}
                                        </button>
                                    </div>
                                </>
                            )}

                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}

export default function StudentPaymentsPage() {
    return (
        <div className="min-h-screen bg-gray-50">
            <Suspense fallback={<div className="min-h-[200px] flex items-center justify-center"><div className="animate-spin rounded-full h-10 w-10 border-4 border-indigo-200 border-t-indigo-600"></div></div>}>
                <StudentPaymentsContent />
            </Suspense>
        </div>
    );
}

