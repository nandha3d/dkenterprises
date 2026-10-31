import React, { useState } from 'react';
import { Expense } from '../types';
import { Language, t, formatINR } from '../services/languageEngine';
import {
  Receipt,
  Plus,
  Filter,
  CreditCard,
  Wallet,
  Building,
  CheckCircle,
  FileSpreadsheet,
  Calendar,
  X
} from 'lucide-react';

interface ExpensesPortalProps {
  lang: Language;
  expenses: Expense[];
  onAddExpense: (expense: Expense) => void;
}

export const ExpensesPortal: React.FC<ExpensesPortalProps> = ({
  lang,
  expenses,
  onAddExpense
}) => {
  const [selectedDivisionFilter, setSelectedDivisionFilter] = useState<'all' | 'tanker' | 'can' | 'bakery' | 'general'>('all');
  const [showAddModal, setShowAddModal] = useState(false);

  // New Expense Form State
  const [newDivision, setNewDivision] = useState<'tanker' | 'can' | 'bakery' | 'general'>('tanker');
  const [newCategory, setNewCategory] = useState('fuel_diesel');
  const [newCategoryName, setNewCategoryName] = useState('Diesel / Fuel');
  const [newVehicle, setNewVehicle] = useState('TN 34 AF 4954');
  const [newAmount, setNewAmount] = useState('2500');
  const [newPayMode, setNewPayMode] = useState<'cash_drawer' | 'gpay_kavin' | 'canara_bank' | 'axis_bank'>('canara_bank');
  const [newPayee, setNewPayee] = useState('');
  const [newNotes, setNewNotes] = useState('');

  const filteredExpenses = selectedDivisionFilter === 'all'
    ? expenses
    : expenses.filter(e => e.division === selectedDivisionFilter);

  const totalExpenseAmount = filteredExpenses.reduce((acc, e) => acc + e.amount, 0);
  const dieselExpenses = expenses.filter(e => e.category === 'fuel_diesel').reduce((acc, e) => acc + e.amount, 0);
  const battaAndWages = expenses.filter(e => e.category === 'driver_batta' || e.category === 'wages_salaries').reduce((acc, e) => acc + e.amount, 0);
  const rawMaterialAndPlant = expenses.filter(e => e.category === 'raw_materials' || e.category === 'water_plant_cost').reduce((acc, e) => acc + e.amount, 0);

  const handleSaveExpense = () => {
    const expense: Expense = {
      id: Date.now(),
      expense_date: new Date().toISOString().split('T')[0],
      division: newDivision,
      category: newCategory,
      category_name: newCategoryName || 'Business Expense',
      vehicle: newVehicle || undefined,
      amount: parseFloat(newAmount) || 0.0,
      payment_mode: newPayMode,
      payee: newPayee || 'Vendor / Payee',
      voucher_no: `EXP-${newDivision.toUpperCase().slice(0, 3)}-${Math.floor(1000 + Math.random() * 9000)}`,
      notes: newNotes
    };

    onAddExpense(expense);
    setShowAddModal(false);
    setNewAmount('');
    setNewPayee('');
    setNewNotes('');
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      {/* 1. Header with Fresh Visual Action Bar */}
      <div className="fresh-card" style={{ padding: '1.25rem 1.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.65rem' }}>
            <span style={{ fontSize: '1.45rem', fontWeight: 800, color: 'var(--text-primary)' }}>
              {lang === 'en' ? 'Business Expense & Cost Management' : 'வணிக செலவுகள் & செலவின மேலாண்மை'}
            </span>
            <span className="status-pill status-pill-amber">
              3-DIVISION LEDGER
            </span>
          </div>
          <p style={{ color: 'var(--text-muted)', fontSize: '0.84rem', marginTop: '0.2rem' }}>
            {lang === 'en'
              ? 'Itemized operational cost tracking for Bulk Tankers, 20L Water Cans, Bakery, and General Administration'
              : 'டேங்கர் டீசல், கேன் விநியோக கூலி, பேக்கரி மூலப்பொருட்கள் மற்றும் பொதுச் செலவுகளின் கணக்கு'}
          </p>
        </div>

        <button
          onClick={() => setShowAddModal(true)}
          className="btn-fresh btn-fresh-primary"
          style={{ padding: '0.65rem 1.25rem', fontSize: '0.9rem' }}
        >
          <Plus size={18} />
          <span>{lang === 'en' ? '+ Record Expense Voucher' : '+ செலவு பற்றுச்சீட்டு பதிவு'}</span>
        </button>
      </div>

      {/* 2. Visuals & Numbers Bento Strip */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '1rem' }}>
        {/* Metric 1: Total Operating Expenses */}
        <div className="fresh-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              Filtered Period Outflow
            </span>
            <span className="status-pill status-pill-red">
              {filteredExpenses.length} Vouchers
            </span>
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', margin: '0.2rem 0' }}>
            <span className="font-mono" style={{ fontSize: '2.1rem', fontWeight: 800, color: '#DC2626' }}>
              {formatINR(totalExpenseAmount)}
            </span>
          </div>
          <div style={{ fontSize: '0.74rem', color: 'var(--text-muted)' }}>
            Cash Drawer + Kavin GPay + Canara Bank
          </div>
        </div>

        {/* Metric 2: Fuel & Diesel Outflow */}
        <div className="fresh-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              Diesel & Fuel Consumed
            </span>
            <span className="status-pill status-pill-blue">
              Lorries & Ace
            </span>
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', margin: '0.2rem 0' }}>
            <span className="font-mono" style={{ fontSize: '2.1rem', fontWeight: 800, color: 'var(--text-primary)' }}>
              {formatINR(dieselExpenses)}
            </span>
          </div>
          <div style={{ fontSize: '0.74rem', color: 'var(--text-dim)' }}>
            HP Kangeyam Road & Indian Oil bunk purchases
          </div>
        </div>

        {/* Metric 3: Driver Batta & Staff Wages */}
        <div className="fresh-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              Wages & Trip Batta
            </span>
            <span className="status-pill status-pill-green">
              Drivers & Staff
            </span>
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', margin: '0.2rem 0' }}>
            <span className="font-mono" style={{ fontSize: '2.1rem', fontWeight: 800, color: '#059669' }}>
              {formatINR(battaAndWages)}
            </span>
          </div>
          <div style={{ fontSize: '0.74rem', color: 'var(--text-muted)' }}>
            Suresh batta, Vignesh day wage, Paati wages
          </div>
        </div>

        {/* Metric 4: Plant Loading & Raw Materials */}
        <div className="fresh-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              Raw Materials & Plant Intake
            </span>
            <span className="status-pill status-pill-amber">
              Water & Bakery
            </span>
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', margin: '0.2rem 0' }}>
            <span className="font-mono" style={{ fontSize: '2.1rem', fontWeight: 800, color: '#D97706' }}>
              {formatINR(rawMaterialAndPlant)}
            </span>
          </div>
          <div style={{ fontSize: '0.74rem', color: 'var(--text-dim)' }}>
            213 Cans @ ₹8 + Mandi ingredients
          </div>
        </div>
      </div>

      {/* 3. Expense Ledger Table */}
      <div className="fresh-card" style={{ padding: '1.25rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem', flexWrap: 'wrap', gap: '0.75rem' }}>
          <div>
            <span style={{ fontWeight: 800, fontSize: '1.05rem' }}>
              Operational Expense Vouchers & Audit Trail
            </span>
            <p style={{ fontSize: '0.76rem', color: 'var(--text-muted)' }}>
              Separated by Cash Drawer, Kavin GPay, and Official Bank Accounts
            </p>
          </div>

          <div style={{ display: 'flex', gap: '0.25rem', background: 'var(--bg-surface-subtle)', padding: '0.2rem', borderRadius: '8px', border: '1px solid var(--border-subtle)', flexWrap: 'wrap' }}>
            {(['all', 'tanker', 'can', 'bakery', 'general'] as const).map(div => (
              <button
                key={div}
                onClick={() => setSelectedDivisionFilter(div)}
                style={{
                  padding: '0.35rem 0.75rem',
                  borderRadius: '6px',
                  border: 'none',
                  fontSize: '0.75rem',
                  fontWeight: 700,
                  cursor: 'pointer',
                  background: selectedDivisionFilter === div ? 'var(--brand-primary)' : 'transparent',
                  color: selectedDivisionFilter === div ? '#FFF' : 'var(--text-secondary)'
                }}
              >
                {div === 'all' ? 'ALL DIVISIONS' : div.toUpperCase()}
              </button>
            ))}
          </div>
        </div>

        <div style={{ overflowX: 'auto' }}>
          <table className="fresh-table">
            <thead>
              <tr>
                <th>Date & Voucher</th>
                <th>Division</th>
                <th>Expense Category</th>
                <th>Vehicle / Asset</th>
                <th>Payee / Vendor</th>
                <th>Payment Mode</th>
                <th>Amount (₹)</th>
                <th>Notes</th>
              </tr>
            </thead>
            <tbody>
              {filteredExpenses.map(exp => (
                <tr key={exp.id}>
                  <td>
                    <div className="font-mono" style={{ fontWeight: 700, fontSize: '0.8rem' }}>{exp.expense_date}</div>
                    <div className="font-mono" style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>{exp.voucher_no}</div>
                  </td>
                  <td>
                    <span className={`status-pill ${exp.division === 'tanker' ? 'status-pill-blue' : exp.division === 'can' ? 'status-pill-green' : exp.division === 'bakery' ? 'status-pill-amber' : 'status-pill-neutral'}`}>
                      {exp.division.toUpperCase()}
                    </span>
                  </td>
                  <td>
                    <div style={{ fontWeight: 700, fontSize: '0.84rem' }}>{exp.category_name}</div>
                  </td>
                  <td>
                    <span className="font-mono" style={{ fontSize: '0.78rem', color: 'var(--text-secondary)' }}>
                      {exp.vehicle || '-'}
                    </span>
                  </td>
                  <td>
                    <div style={{ fontSize: '0.82rem' }}>{exp.payee}</div>
                  </td>
                  <td>
                    <span className={`status-pill ${exp.payment_mode === 'cash_drawer' ? 'status-pill-green' : exp.payment_mode === 'gpay_kavin' ? 'status-pill-blue' : 'status-pill-neutral'}`}>
                      {exp.payment_mode === 'cash_drawer' ? 'CASH DRAWER' : exp.payment_mode === 'gpay_kavin' ? 'GPAY KAVIN' : 'CANARA / AXIS'}
                    </span>
                  </td>
                  <td>
                    <span className="font-mono" style={{ fontWeight: 800, fontSize: '0.98rem', color: '#DC2626' }}>
                      {formatINR(exp.amount)}
                    </span>
                  </td>
                  <td>
                    <div style={{ fontSize: '0.74rem', color: 'var(--text-muted)' }}>{exp.notes || '-'}</div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* 4. Modal: Add Expense */}
      {showAddModal && (
        <div className="fresh-modal-backdrop" onClick={() => setShowAddModal(false)}>
          <div className="fresh-modal-dialog" onClick={e => e.stopPropagation()} style={{ maxWidth: '520px' }}>
            <div style={{ padding: '1.25rem 1.5rem', borderBottom: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <Receipt size={20} color="var(--brand-primary)" />
                <span style={{ fontWeight: 800, fontSize: '1.15rem' }}>
                  Record Business Expense Voucher
                </span>
              </div>
              <button
                onClick={() => setShowAddModal(false)}
                style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-muted)' }}
              >
                <X size={20} />
              </button>
            </div>

            <div style={{ padding: '1.5rem', display: 'flex', flexDirection: 'column', gap: '0.9rem' }}>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    Business Vertical:
                  </label>
                  <select
                    className="fresh-input"
                    value={newDivision}
                    onChange={e => setNewDivision(e.target.value as any)}
                  >
                    <option value="tanker">Bulk Water Tankers</option>
                    <option value="can">20L Water Can Distribution</option>
                    <option value="bakery">Bakery & Store</option>
                    <option value="general">General / Overhead</option>
                  </select>
                </div>

                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    Expense Category:
                  </label>
                  <select
                    className="fresh-input"
                    value={newCategory}
                    onChange={e => {
                      setNewCategory(e.target.value);
                      const nameMap: Record<string, string> = {
                        fuel_diesel: 'Diesel / Fuel',
                        driver_batta: 'Driver Batta',
                        vehicle_service: 'Vehicle Maintenance & Spares',
                        water_plant_cost: 'RO Plant Water Intake',
                        raw_materials: 'Raw Materials & Ingredients',
                        tolls_permits: 'Highway Tolls & Permits',
                        wages_salaries: 'Staff Wages / Salaries',
                        electricity_utilities: 'Electricity / Utilities',
                        finance_instalment: 'Finance Instalment',
                        miscellaneous: 'Miscellaneous Cost'
                      };
                      setNewCategoryName(nameMap[e.target.value] || 'Business Expense');
                    }}
                  >
                    <option value="fuel_diesel">Diesel / Fuel</option>
                    <option value="driver_batta">Driver Batta</option>
                    <option value="vehicle_service">Vehicle Maintenance & Spares</option>
                    <option value="water_plant_cost">RO Plant Water Intake</option>
                    <option value="raw_materials">Raw Materials & Ingredients</option>
                    <option value="tolls_permits">Highway Tolls & Permits</option>
                    <option value="wages_salaries">Staff Wages / Salaries</option>
                    <option value="electricity_utilities">Electricity / Utilities</option>
                    <option value="finance_instalment">Finance Instalment</option>
                    <option value="miscellaneous">Miscellaneous Cost</option>
                  </select>
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    Amount (₹):
                  </label>
                  <input
                    type="number"
                    className="fresh-input font-mono"
                    value={newAmount}
                    onChange={e => setNewAmount(e.target.value)}
                  />
                </div>

                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    Payment Mode:
                  </label>
                  <select
                    className="fresh-input"
                    value={newPayMode}
                    onChange={e => setNewPayMode(e.target.value as any)}
                  >
                    <option value="cash_drawer">Cash Drawer</option>
                    <option value="gpay_kavin">Kavin Anna GPay</option>
                    <option value="canara_bank">Canara Bank Current A/c</option>
                    <option value="axis_bank">Axis Bank</option>
                  </select>
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    Payee / Vendor:
                  </label>
                  <input
                    type="text"
                    className="fresh-input"
                    placeholder="Vendor Name, HP Bunk, Garage..."
                    value={newPayee}
                    onChange={e => setNewPayee(e.target.value)}
                  />
                </div>

                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    Vehicle / Asset:
                  </label>
                  <input
                    type="text"
                    className="fresh-input font-mono"
                    placeholder="TN 34 AF 4954 or Store"
                    value={newVehicle}
                    onChange={e => setNewVehicle(e.target.value)}
                  />
                </div>
              </div>

              <div>
                <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                  Notes / Receipt Reference:
                </label>
                <input
                  type="text"
                  className="fresh-input"
                  placeholder="Bill number, litre count, or description..."
                  value={newNotes}
                  onChange={e => setNewNotes(e.target.value)}
                />
              </div>
            </div>

            <div style={{ padding: '1rem 1.5rem', borderTop: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'flex-end', gap: '0.75rem' }}>
              <button
                onClick={() => setShowAddModal(false)}
                className="btn-fresh btn-fresh-outline"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveExpense}
                className="btn-fresh btn-fresh-primary"
              >
                Record Expense
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
