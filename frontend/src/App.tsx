import { useState, useEffect } from 'react';
import {
  PortalType,
  Vehicle,
  TankerTrip,
  PlantIntake,
  CanDelivery,
  BakeryPurchase,
  BakeryClosing,
  Customer,
  Expense,
  StaffMember,
  AttendanceRecord,
  PayrollRecord,
  LeaveRecord
} from './types';
import { Language, t } from './services/languageEngine';
import {
  initialVehicles,
  initialTankerTrips,
  initialPlantIntakes,
  initialCanDeliveries,
  initialRouteStops,
  initialBakeryPurchases,
  initialBakeryClosing,
  initialCreditAccounts,
  initialCustomers,
  initialExpenses,
  initialStaff,
  initialAttendance,
  initialPayroll,
  initialLeaves
} from './data/mockData';
import { TopApexBar } from './components/TopApexBar';
import { ExecutivePortal } from './portals/ExecutivePortal';
import { TankersPortal } from './portals/TankersPortal';
import { WaterCansPortal } from './portals/WaterCansPortal';
import { BakeryPortal } from './portals/BakeryPortal';
import { CustomersPortal } from './portals/CustomersPortal';
import { FleetPortal } from './portals/FleetPortal';
import { ExpensesPortal } from './portals/ExpensesPortal';
import { TelematicsPortal } from './portals/TelematicsPortal';
import { StaffPortal } from './portals/StaffPortal';
import { MobileSimulatorModal } from './portals/MobileSimulatorModal';
import { ShieldCheck, Server, Layers, Cpu } from 'lucide-react';

export function App() {
  // Prime Directives: Default English, Light Theme option, Standalone
  const [currentPortal, setCurrentPortal] = useState<PortalType>('executive');
  const [lang, setLang] = useState<Language>('en'); // DEFAULT IS ENGLISH
  const [theme, setTheme] = useState<'light' | 'dark'>('light'); // DEFAULT IS FRESH LIGHT THEME
  const [isMobileSimOpen, setIsMobileSimOpen] = useState(false);

  // Live Shared State across Portals
  const [vehicles, setVehicles] = useState<Vehicle[]>(initialVehicles);
  const [tankerTrips, setTankerTrips] = useState<TankerTrip[]>(initialTankerTrips);
  const [plantIntakes, setPlantIntakes] = useState<PlantIntake[]>(initialPlantIntakes);
  const [canDeliveries, setCanDeliveries] = useState<CanDelivery[]>(initialCanDeliveries);
  const [routeStops] = useState(initialRouteStops);
  const [bakeryPurchases, setBakeryPurchases] = useState<BakeryPurchase[]>(initialBakeryPurchases);
  const [bakeryClosing, setBakeryClosing] = useState<BakeryClosing>(initialBakeryClosing);
  const [creditAccounts] = useState(initialCreditAccounts);

  // New modules: Customers, Expenses, Staff, Attendance, Payroll, Leaves
  const [customers, setCustomers] = useState<Customer[]>(initialCustomers);
  const [expenses, setExpenses] = useState<Expense[]>(initialExpenses);
  const [staffList, setStaffList] = useState<StaffMember[]>(initialStaff);
  const [attendanceRecords, setAttendanceRecords] = useState<AttendanceRecord[]>(initialAttendance);
  const [payrollRecords, setPayrollRecords] = useState<PayrollRecord[]>(initialPayroll);
  const [leaveRecords, setLeaveRecords] = useState<LeaveRecord[]>(initialLeaves);

  // Apply Theme to DOM root
  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
  }, [theme]);

  const toggleLanguage = () => {
    setLang(prev => (prev === 'en' ? 'ta' : 'en'));
  };

  const toggleTheme = () => {
    setTheme(prev => (prev === 'light' ? 'dark' : 'light'));
  };

  const handleUpdateGeoLock = (customerId: number, lat: number, lng: number, radius: number) => {
    setCustomers(prev => prev.map(c => {
      if (c.id === customerId) {
        return {
          ...c,
          delivery_location_lat: lat,
          delivery_location_lng: lng,
          geofence_radius_meters: radius,
          is_gps_locked: true
        };
      }
      return c;
    }));
  };

  return (
    <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column', background: 'var(--bg-app)', transition: 'background-color 0.2s ease' }}>
      {/* 1. Global Apex Navigation with Theme and Language Toggles */}
      <TopApexBar
        currentPortal={currentPortal}
        onSelectPortal={setCurrentPortal}
        lang={lang}
        onToggleLang={toggleLanguage}
        theme={theme}
        onToggleTheme={toggleTheme}
        onOpenMobileSimulator={() => setIsMobileSimOpen(true)}
      />

      {/* 2. Dedicated Vertical Portal Content */}
      <main style={{ flex: 1, padding: '1.25rem', maxWidth: '1600px', width: '100%', margin: '0 auto' }}>
        {currentPortal === 'executive' && (
          <ExecutivePortal
            lang={lang}
            creditAccounts={creditAccounts}
            onNavigateToVertical={(portal) => setCurrentPortal(portal)}
          />
        )}

        {currentPortal === 'tankers' && (
          <TankersPortal
            lang={lang}
            vehicles={vehicles}
            trips={tankerTrips}
            onAddNewTrip={(newTrip) => setTankerTrips(prev => [newTrip, ...prev])}
          />
        )}

        {currentPortal === 'water-cans' && (
          <WaterCansPortal
            lang={lang}
            vehicles={vehicles}
            plantIntakes={plantIntakes}
            deliveries={canDeliveries}
            routeStops={routeStops}
            onAddPlantIntake={(newIntake) => setPlantIntakes(prev => [...prev, newIntake])}
            onAddDelivery={(newDelivery) => setCanDeliveries(prev => [newDelivery, ...prev])}
          />
        )}

        {currentPortal === 'bakery' && (
          <BakeryPortal
            lang={lang}
            purchases={bakeryPurchases}
            closing={bakeryClosing}
            onAddPurchase={(newPurchase) => setBakeryPurchases(prev => [newPurchase, ...prev])}
            onUpdateClosing={setBakeryClosing}
          />
        )}

        {currentPortal === 'customers' && (
          <CustomersPortal
            lang={lang}
            customers={customers}
            onAddCustomer={(newCust) => setCustomers(prev => [newCust, ...prev])}
            onUpdateGeoLock={handleUpdateGeoLock}
          />
        )}

        {currentPortal === 'fleet' && (
          <FleetPortal
            lang={lang}
            vehicles={vehicles}
            onAddVehicle={(newVeh) => setVehicles(prev => [...prev, newVeh])}
          />
        )}

        {currentPortal === 'expenses' && (
          <ExpensesPortal
            lang={lang}
            expenses={expenses}
            onAddExpense={(newExp) => setExpenses(prev => [newExp, ...prev])}
          />
        )}

        {currentPortal === 'telematics' && (
          <TelematicsPortal
            lang={lang}
            vehicles={vehicles}
            deliveries={canDeliveries}
            routeStops={routeStops}
          />
        )}

        {currentPortal === 'staff' && (
          <StaffPortal
            lang={lang}
            staffList={staffList}
            attendanceRecords={attendanceRecords}
            payrollRecords={payrollRecords}
            leaveRecords={leaveRecords}
            onAddStaff={(newStaff) => setStaffList(prev => [...prev, newStaff])}
            onMarkAttendance={(record) => setAttendanceRecords(prev => [record, ...prev])}
            onDisbursePayroll={(record) => setPayrollRecords(prev => [record, ...prev])}
            onRequestLeave={(record) => setLeaveRecords(prev => [record, ...prev])}
          />
        )}
      </main>

      {/* 3. Operational Integrity & Hosting Footer */}
      <footer style={{ background: 'var(--bg-surface)', borderTop: '1px solid var(--border-subtle)', padding: '0.85rem 1.5rem', color: 'var(--text-muted)', fontSize: '0.75rem', marginTop: 'auto' }}>
        <div style={{ maxWidth: '1600px', margin: '0 auto', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '1.25rem', flexWrap: 'wrap' }}>
            <span style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', color: 'var(--accent-emerald)', fontWeight: 700 }}>
              <ShieldCheck size={14} /> DK Enterprises ERP
            </span>
            <span style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
              <Server size={14} /> Shared Hosting Safe (Hostinger / cPanel)
            </span>
            <span style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
              <Layers size={14} /> 3 Dedicated Portals + Executive Command
            </span>
            <span style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
              <Cpu size={14} /> Infinite Capacity & Dynamic Surcharges
            </span>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
            <span>Default: English · Convertible Tamil (தமிழ்)</span>
            <span>•</span>
            <button
              onClick={() => setIsMobileSimOpen(true)}
              style={{
                background: 'none',
                border: 'none',
                color: 'var(--brand-primary)',
                cursor: 'pointer',
                fontWeight: 700,
                textDecoration: 'underline'
              }}
            >
              Open Mobile Simulator
            </button>
          </div>
        </div>
      </footer>

      {/* 4. Field Driver Mobile Simulator Modal */}
      <MobileSimulatorModal
        isOpen={isMobileSimOpen}
        onClose={() => setIsMobileSimOpen(false)}
        lang={lang}
        onNewDeliverySimulated={(newDelivery) => setCanDeliveries(prev => [newDelivery, ...prev])}
      />
    </div>
  );
}

export default App;
