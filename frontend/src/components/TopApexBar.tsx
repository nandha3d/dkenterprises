import React from 'react';
import { PortalType } from '../types';
import { Language, t } from '../services/languageEngine';
import {
  Truck,
  Droplets,
  Store,
  LayoutDashboard,
  Globe,
  Smartphone,
  Sun,
  Moon,
  ShieldCheck,
  Fuel,
  TrendingUp,
  AlertCircle,
  Users,
  MapPin,
  Receipt,
  Navigation
} from 'lucide-react';

interface TopApexBarProps {
  currentPortal: PortalType;
  onSelectPortal: (portal: PortalType) => void;
  lang: Language;
  onToggleLang: () => void;
  theme: 'light' | 'dark';
  onToggleTheme: () => void;
  onOpenMobileSimulator: () => void;
}

export const TopApexBar: React.FC<TopApexBarProps> = ({
  currentPortal,
  onSelectPortal,
  lang,
  onToggleLang,
  theme,
  onToggleTheme,
  onOpenMobileSimulator
}) => {
  return (
    <header style={{ background: 'var(--bg-surface)', borderBottom: '1px solid var(--border-subtle)', position: 'sticky', top: 0, zIndex: 100, transition: 'background-color 0.2s ease' }}>
      {/* 1. Ultra-Clean Operational Ticker Strip */}
      <div
        style={{
          background: theme === 'light' ? '#0F172A' : '#080C14',
          color: '#E2E8F0',
          padding: '0.35rem 1.25rem',
          fontSize: '0.74rem',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          flexWrap: 'wrap',
          gap: '1rem',
          fontFamily: 'var(--font-mono)'
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '1.25rem' }}>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: '0.4rem', color: '#10B981', fontWeight: 700 }}>
            <ShieldCheck size={13} /> DK ENTERPRISES · SINGLE-TENANT
          </span>
          <span style={{ color: '#94A3B8' }}>•</span>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: '0.35rem', color: '#38BDF8' }}>
            <Truck size={12} /> 6/7 LORRIES DISPATCHED
          </span>
          <span style={{ color: '#94A3B8' }}>•</span>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: '0.35rem', color: '#FBBF24' }}>
            <Fuel size={12} /> DIESEL: ₹8,420
          </span>
          <span style={{ color: '#94A3B8' }}>•</span>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: '0.35rem', color: '#34D399' }}>
            <TrendingUp size={12} /> TODAY: ₹1,48,500
          </span>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', color: '#94A3B8' }}>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: '0.3rem', color: '#F87171' }}>
            <AlertCircle size={12} /> VINAYAGA OVERDUE: 60+ DAYS
          </span>
        </div>
      </div>

      {/* 2. Main Navigation Bar */}
      <div
        style={{
          maxWidth: '1600px',
          margin: '0 auto',
          padding: '0.75rem 1.25rem',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          gap: '1rem',
          flexWrap: 'wrap'
        }}
      >
        {/* Brand Header */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.85rem' }}>
          <div
            style={{
              background: 'linear-gradient(135deg, #0284C7, #0369A1)',
              padding: '0.55rem',
              borderRadius: '10px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              boxShadow: '0 2px 8px rgba(2, 132, 199, 0.3)'
            }}
          >
            <Truck size={20} color="#FFFFFF" />
          </div>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <span style={{ fontSize: '1.2rem', fontWeight: 800, color: 'var(--text-primary)', letterSpacing: '-0.02em' }}>
                {t('app.name', lang)}
              </span>
              <span className="status-pill status-pill-green">
                <span className="live-pulse-dot" style={{ width: '6px', height: '6px' }}></span>
                {t('common.active', lang)}
              </span>
            </div>
            <div style={{ fontSize: '0.74rem', color: 'var(--text-muted)' }}>
              {t('app.tagline', lang)}
            </div>
          </div>
        </div>

        {/* 3 Dedicated Vertical Portals + Master Executive Navigation Tabs */}
        <nav
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '0.25rem',
            background: 'var(--bg-surface-subtle)',
            padding: '0.3rem',
            borderRadius: '10px',
            border: '1px solid var(--border-subtle)'
          }}
        >
          {/* Master Executive Portal */}
          <button
            onClick={() => onSelectPortal('executive')}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '0.45rem',
              padding: '0.5rem 0.9rem',
              borderRadius: '8px',
              border: 'none',
              cursor: 'pointer',
              fontSize: '0.82rem',
              fontWeight: 700,
              background: currentPortal === 'executive' ? 'var(--bg-surface)' : 'transparent',
              color: currentPortal === 'executive' ? 'var(--brand-primary)' : 'var(--text-secondary)',
              boxShadow: currentPortal === 'executive' ? 'var(--shadow-sm)' : 'none',
              transition: 'all 0.15s ease'
            }}
          >
            <LayoutDashboard size={16} />
            <span>{t('portal.executive', lang)}</span>
          </button>

          {/* Bulk Tankers Vertical */}
          <button
            onClick={() => onSelectPortal('tankers')}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '0.45rem',
              padding: '0.5rem 0.9rem',
              borderRadius: '8px',
              border: 'none',
              cursor: 'pointer',
              fontSize: '0.82rem',
              fontWeight: 700,
              background: currentPortal === 'tankers' ? 'var(--bg-surface)' : 'transparent',
              color: currentPortal === 'tankers' ? '#0284C7' : 'var(--text-secondary)',
              boxShadow: currentPortal === 'tankers' ? 'var(--shadow-sm)' : 'none',
              transition: 'all 0.15s ease'
            }}
          >
            <Truck size={16} />
            <span>{t('portal.tankers', lang)}</span>
          </button>

          {/* Water Cans Vertical */}
          <button
            onClick={() => onSelectPortal('water-cans')}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '0.45rem',
              padding: '0.5rem 0.9rem',
              borderRadius: '8px',
              border: 'none',
              cursor: 'pointer',
              fontSize: '0.82rem',
              fontWeight: 700,
              background: currentPortal === 'water-cans' ? 'var(--bg-surface)' : 'transparent',
              color: currentPortal === 'water-cans' ? '#059669' : 'var(--text-secondary)',
              boxShadow: currentPortal === 'water-cans' ? 'var(--shadow-sm)' : 'none',
              transition: 'all 0.15s ease'
            }}
          >
            <Droplets size={16} />
            <span>{t('portal.water_cans', lang)}</span>
          </button>

          {/* Bakery & Store Vertical */}
          <button
            onClick={() => onSelectPortal('bakery')}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '0.45rem',
              padding: '0.5rem 0.85rem',
              borderRadius: '8px',
              border: 'none',
              cursor: 'pointer',
              fontSize: '0.82rem',
              fontWeight: 700,
              background: currentPortal === 'bakery' ? 'var(--bg-surface)' : 'transparent',
              color: currentPortal === 'bakery' ? '#D97706' : 'var(--text-secondary)',
              boxShadow: currentPortal === 'bakery' ? 'var(--shadow-sm)' : 'none',
              transition: 'all 0.15s ease'
            }}
          >
            <Store size={15} />
            <span>{t('portal.bakery', lang)}</span>
          </button>

          {/* Customers & Geo-Lock */}
          <button
            onClick={() => onSelectPortal('customers')}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '0.45rem',
              padding: '0.5rem 0.85rem',
              borderRadius: '8px',
              border: 'none',
              cursor: 'pointer',
              fontSize: '0.82rem',
              fontWeight: 700,
              background: currentPortal === 'customers' ? 'var(--bg-surface)' : 'transparent',
              color: currentPortal === 'customers' ? 'var(--brand-primary)' : 'var(--text-secondary)',
              boxShadow: currentPortal === 'customers' ? 'var(--shadow-sm)' : 'none',
              transition: 'all 0.15s ease'
            }}
          >
            <MapPin size={15} />
            <span>{lang === 'en' ? 'Customers & Geo-Lock' : 'வாடிக்கையாளர்கள்'}</span>
          </button>

          {/* Fleet & Trucks */}
          <button
            onClick={() => onSelectPortal('fleet')}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '0.45rem',
              padding: '0.5rem 0.85rem',
              borderRadius: '8px',
              border: 'none',
              cursor: 'pointer',
              fontSize: '0.82rem',
              fontWeight: 700,
              background: currentPortal === 'fleet' ? 'var(--bg-surface)' : 'transparent',
              color: currentPortal === 'fleet' ? '#0284C7' : 'var(--text-secondary)',
              boxShadow: currentPortal === 'fleet' ? 'var(--shadow-sm)' : 'none',
              transition: 'all 0.15s ease'
            }}
          >
            <Truck size={15} />
            <span>{lang === 'en' ? 'Fleet & Trucks' : 'வாகனங்கள்'}</span>
          </button>

          {/* Business Expenses */}
          <button
            onClick={() => onSelectPortal('expenses')}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '0.45rem',
              padding: '0.5rem 0.85rem',
              borderRadius: '8px',
              border: 'none',
              cursor: 'pointer',
              fontSize: '0.82rem',
              fontWeight: 700,
              background: currentPortal === 'expenses' ? 'var(--bg-surface)' : 'transparent',
              color: currentPortal === 'expenses' ? '#DC2626' : 'var(--text-secondary)',
              boxShadow: currentPortal === 'expenses' ? 'var(--shadow-sm)' : 'none',
              transition: 'all 0.15s ease'
            }}
          >
            <Receipt size={15} />
            <span>{lang === 'en' ? 'Expenses' : 'செலவுகள்'}</span>
          </button>

          {/* GPS Telematics */}
          <button
            onClick={() => onSelectPortal('telematics')}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '0.45rem',
              padding: '0.5rem 0.85rem',
              borderRadius: '8px',
              border: 'none',
              cursor: 'pointer',
              fontSize: '0.82rem',
              fontWeight: 700,
              background: currentPortal === 'telematics' ? 'var(--bg-surface)' : 'transparent',
              color: currentPortal === 'telematics' ? '#059669' : 'var(--text-secondary)',
              boxShadow: currentPortal === 'telematics' ? 'var(--shadow-sm)' : 'none',
              transition: 'all 0.15s ease'
            }}
          >
            <Navigation size={15} />
            <span>{lang === 'en' ? 'GPS Telematics' : 'GPS கண்காணிப்பு'}</span>
          </button>

          {/* Staff, Drivers & Payroll */}
          <button
            onClick={() => onSelectPortal('staff')}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '0.45rem',
              padding: '0.5rem 0.85rem',
              borderRadius: '8px',
              border: 'none',
              cursor: 'pointer',
              fontSize: '0.82rem',
              fontWeight: 700,
              background: currentPortal === 'staff' ? 'var(--bg-surface)' : 'transparent',
              color: currentPortal === 'staff' ? '#7C3AED' : 'var(--text-secondary)',
              boxShadow: currentPortal === 'staff' ? 'var(--shadow-sm)' : 'none',
              transition: 'all 0.15s ease'
            }}
          >
            <Users size={15} />
            <span>{lang === 'en' ? 'Staff & Payroll' : 'ஊழியர்கள் & சம்பளம்'}</span>
          </button>
        </nav>

        {/* Action Controls: Theme Switcher, Language Toggle, Mobile Simulator */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          {/* Light / Dark Mode Toggle */}
          <button
            onClick={onToggleTheme}
            className="btn-fresh btn-fresh-outline"
            style={{ padding: '0.5rem 0.75rem', fontSize: '0.78rem' }}
            title={theme === 'light' ? t('theme.dark', lang) : t('theme.light', lang)}
          >
            {theme === 'light' ? <Moon size={15} color="#475569" /> : <Sun size={15} color="#FBBF24" />}
            <span>{theme === 'light' ? t('theme.dark', lang) : t('theme.light', lang)}</span>
          </button>

          {/* Language Switcher (Default English, converts to Tamil) */}
          <button
            onClick={onToggleLang}
            className="btn-fresh btn-fresh-outline"
            style={{ padding: '0.5rem 0.75rem', fontSize: '0.78rem' }}
          >
            <Globe size={15} color="var(--brand-primary)" />
            <span style={{ fontWeight: 700, color: 'var(--brand-primary)' }}>
              {lang === 'en' ? 'தமிழ் (Tamil)' : 'English'}
            </span>
          </button>

          {/* Field Driver Mobile Simulator Button */}
          <button
            onClick={onOpenMobileSimulator}
            className="btn-fresh btn-fresh-primary"
            style={{ padding: '0.5rem 0.9rem', fontSize: '0.78rem' }}
          >
            <Smartphone size={15} />
            <span>{t('portal.mobile_app', lang)}</span>
          </button>
        </div>
      </div>
    </header>
  );
};
