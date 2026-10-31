/**
 * DK Track — Dynamic Bilingual Translation & Localization Engine
 * English is DEFAULT. Comprehensive Tamil (தமிழ்) translation for every word.
 * Automatically translates newly added features and dynamic domain terms.
 */

export type Language = 'en' | 'ta';

// Comprehensive Core Terminology & Dictionary
export const translations: Record<string, { en: string; ta: string }> = {
  // Navigation & Global Apex Bar
  'app.name': { en: 'DK Track', ta: 'டிகே ட்ராக்' },
  'app.tagline': { en: 'Custom ERP & Logistics Control Plane', ta: 'தனிப்பயன் ERP & தளவாட மேலாண்மை' },
  'app.single_tenant': { en: 'Dedicated Single-Tenant ERP', ta: 'தனிப்பயன் ஒற்றை-வாடகைதாரர் ERP' },
  'theme.light': { en: 'Light Mode', ta: 'பகல் தோற்றம்' },
  'theme.dark': { en: 'Dark Mode', ta: 'இரவு தோற்றம்' },
  'lang.english': { en: 'English', ta: 'English' },
  'lang.tamil': { en: 'தமிழ்', ta: 'தமிழ்' },
  'lang.switch': { en: 'Switch Language', ta: 'மொழியை மாற்று' },

  // Portals Navigation Tabs
  'portal.executive': { en: 'Master Executive', ta: 'தலைமை நிர்வாகம்' },
  'portal.tankers': { en: 'Bulk Water Tankers', ta: 'பல்க் டேங்கர் லாரிகள்' },
  'portal.water_cans': { en: '20L Water Cans', ta: '20லி வாட்டர் கேன்கள்' },
  'portal.bakery': { en: 'Bakery & Store', ta: 'பேக்கரி & சில்லறை கடை' },
  'portal.mobile_app': { en: 'Driver App Simulator', ta: 'ஓட்டுனர் மொபைல் சிமுலேட்டர்' },

  // Common UI Actions & Common Terms
  'common.search': { en: 'Search...', ta: 'தேடுக...' },
  'common.filter': { en: 'Filter', ta: 'வடிகட்டு' },
  'common.all': { en: 'All', ta: 'அனைத்தும்' },
  'common.save': { en: 'Save', ta: 'சேமி' },
  'common.cancel': { en: 'Cancel', ta: 'ரத்து செய்' },
  'common.confirm': { en: 'Confirm', ta: 'உறுதி செய்' },
  'common.close': { en: 'Close', ta: 'மூடு' },
  'common.status': { en: 'Status', ta: 'நிலை' },
  'common.date': { en: 'Date', ta: 'தேதி' },
  'common.time': { en: 'Time', ta: 'நேரம்' },
  'common.actions': { en: 'Actions', ta: 'செயல்கள்' },
  'common.details': { en: 'Details', ta: 'விவரங்கள்' },
  'common.export': { en: 'Export', ta: 'ஏற்றுமதி' },
  'common.print': { en: 'Print', ta: 'அச்சிடு' },
  'common.refresh': { en: 'Refresh', ta: 'புதுப்பி' },
  'common.verified': { en: 'Verified', ta: 'சரிபார்க்கப்பட்டது' },
  'common.warning': { en: 'Warning', ta: 'எச்சரிக்கை' },
  'common.active': { en: 'Active', ta: 'இயங்குகிறது' },
  'common.standby': { en: 'Standby', ta: 'தயார் நிலை' },
  'common.maintenance': { en: 'Maintenance', ta: 'பராமரிப்பில்' },
  'common.completed': { en: 'Completed', ta: 'முடிவடைந்தது' },
  'common.in_transit': { en: 'In Transit', ta: 'பயணத்தில்' },
  'common.at_destination': { en: 'At Destination', ta: 'சேருமிடத்தில்' },
  'common.stopped': { en: 'Stopped', ta: 'நிறுத்தப்பட்டுள்ளது' },
  'common.total': { en: 'Total', ta: 'மொத்தம்' },
  'common.today': { en: 'Today', ta: 'இன்று' },
  'common.yesterday': { en: 'Yesterday', ta: 'நேற்று' },
  'common.amount': { en: 'Amount', ta: 'தொகை' },
  'common.rate': { en: 'Rate', ta: 'விலை' },
  'common.quantity': { en: 'Quantity', ta: 'அளவு' },
  'common.customer': { en: 'Customer / Client', ta: 'வாடிக்கையாளர் / நிறுவனம்' },
  'common.vehicle': { en: 'Vehicle', ta: 'வாகனம்' },
  'common.driver': { en: 'Driver', ta: 'ஓட்டுனர்' },
  'common.odometer': { en: 'Odometer', ta: 'கிலோமீட்டர் மீட்டர்' },
  'common.km': { en: 'km', ta: 'கி.மீ' },
  'common.litres': { en: 'Litres', ta: 'லிட்டர்கள்' },
  'common.hours': { en: 'hours', ta: 'மணிநேரம்' },
  'common.minutes': { en: 'mins', ta: 'நிமிடங்கள்' },
  'common.rupees': { en: '₹', ta: '₹' },

  // Master Executive Dashboard
  'exec.title': { en: 'Executive Command Center', ta: 'தலைமை நிர்வாக கட்டுப்பாட்டு மையம்' },
  'exec.subtitle': { en: 'Aggregated Money In vs Money Out · Real-time Bank Liquidity · Corporate Receivables', ta: 'மொத்த வரவு vs செலவு · நிகழ்நேர வங்கி இருப்பு · கார்ப்பரேட் வரவுகள்' },
  'exec.gross_money_in': { en: 'Gross Money In', ta: 'மொத்த வரவு (பணம் வந்தது)' },
  'exec.gross_money_out': { en: 'Gross Money Out', ta: 'மொத்த செலவு (பணம் போனது)' },
  'exec.net_profit': { en: 'Net Operating Profit', ta: 'நிகர இயக்க லாபம்' },
  'exec.margin': { en: 'Profit Margin', ta: 'லாப வரம்பு' },
  'exec.liquidity_ribbon': { en: 'Bank & Safe Liquid Accounts', ta: 'வங்கி & பணப்பெட்டி நேரடி இருப்பு' },
  'exec.canara_bank': { en: 'Canara Bank (Kavin)', ta: 'கனரா வங்கி (கவின்)' },
  'exec.axis_bank': { en: 'Axis Bank (GPay)', ta: 'ஆக்ஸிஸ் வங்கி (GPay)' },
  'exec.cash_safe': { en: 'Cash in Safe / Drawer', ta: 'பணப்பெட்டி / கல்லா இருப்பு' },
  'exec.total_liquidity': { en: 'Total Available Liquidity', ta: 'மொத்த கைவசம் உள்ள ரொக்கம்' },
  'exec.division_title': { en: 'Performance by Business Division', ta: 'பிரிவு வாரியான வருவாய் மற்றும் லாபம்' },
  'exec.corporate_receivables': { en: 'Corporate B2B Receivables & Aging', ta: 'நிறுவன வரவுகள் & கடன் காலக்கெடு ஆய்வு' },
  'exec.aging_0_15': { en: 'Current (0-15 Days)', ta: 'நடப்பு (0-15 நாட்கள்)' },
  'exec.aging_16_30': { en: '16-30 Days', ta: '16-30 நாட்கள்' },
  'exec.aging_31_60': { en: '31-60 Days', ta: '31-60 நாட்கள்' },
  'exec.aging_60_plus': { en: 'Critical Overdue (60+ Days)', ta: 'ஆபத்தான நிலுவை (60+ நாட்கள்)' },
  'exec.tax_export_btn': { en: 'Auditor Tax P&L Export (.xlsx)', ta: 'ஆடிட்டர் வரி அறிக்கை ஏற்றுமதி (.xlsx)' },
  'exec.tax_export_title': { en: '1-Click Income Tax Audit Summary', ta: '1-கிளிக் வருமான வரி தணிக்கை சுருக்கம்' },
  'exec.tax_export_subtitle': { en: 'Pre-formatted for DK Enterprises partnership IT returns', ta: 'DK எண்டர்பிரைசஸ் வருமான வரி கணக்கிற்காக தயாரிக்கப்பட்டது' },

  // Bulk Water Tankers Portal & Trip Sheet Rules
  'tankers.title': { en: 'Bulk Water Tanker Fleet', ta: 'பல்க் டேங்கர் லாரி பிரிவு' },
  'tankers.subtitle': { en: 'Real-time lorry allocation, 9KL to 40KL+ custom capacities, and surcharge tracking', ta: 'நிகழ்நேர லாரி ஒதுக்கீடு, 9KL முதல் 40KL+ வரை தனிப்பயன் கொள்ளளவு, கூடுதல் கட்டணங்கள்' },
  'tankers.new_dispatch': { en: '+ New Tanker Dispatch', ta: '+ புதிய டேங்கர் ட்ரிப் அனுப்பு' },
  'tankers.active_fleet': { en: 'Fleet Running Ratio', ta: 'சாலையில் ஓடும் லாரிகள்' },
  'tankers.water_moved': { en: 'Water Volume Delivered', ta: 'வழங்கப்பட்ட மொத்த தண்ணீர்' },
  'tankers.diesel_burn': { en: 'Diesel Refuels Today', ta: 'இன்றைய டீசல் செலவு' },
  'tankers.unbilled_trips': { en: 'Unbilled Corporate Trips', ta: 'இன்னும் பில் போடப்படாத ட்ரிப்புகள்' },
  'tankers.custom_capacity': { en: 'Tank Capacity (KL)', ta: 'டேங்கர் கொள்ளளவு (KL)' },
  'tankers.base_fare': { en: 'Base Trip Fare (₹)', ta: 'அடிப்படை ட்ரிப் கட்டணம் (₹)' },
  'tankers.motor_used': { en: 'Pumping Motor Used', ta: 'மோட்டார் மூலம் தண்ணீர் ஏற்றப்பட்டது' },
  'tankers.motor_minutes': { en: 'Motor Running Duration (Minutes)', ta: 'மோட்டார் ஓடிய நேரம் (நிமிடங்கள்)' },
  'tankers.motor_rate_per_min': { en: 'Motor Rate / Min (₹)', ta: 'மோட்டார் கட்டணம் / நிமிடம் (₹)' },
  'tankers.motor_charge': { en: 'Motor Pumping Charge (+₹)', ta: 'மோட்டார் இறைப்பு கட்டணம் (+₹)' },
  'tankers.min_distance_included': { en: 'Min Base Distance Included (km)', ta: 'அடிப்படை கட்டணத்தில் அடங்கிய தூரம் (கி.மீ)' },
  'tankers.actual_distance_km': { en: 'Total Trip Distance (km)', ta: 'மொத்த பயண தூரம் (கி.மீ)' },
  'tankers.extra_distance_km': { en: 'Extra Distance Beyond Min (km)', ta: 'அடிப்படைக்கு மேல் கூடுதல் தூரம் (கி.மீ)' },
  'tankers.distance_rate_per_km': { en: 'Extra Distance Rate / km (₹)', ta: 'கூடுதல் தூரக் கட்டணம் / கி.மீ (₹)' },
  'tankers.distance_charge': { en: 'Distance Surcharge (+₹)', ta: 'தூரக் கட்டணம் (+₹)' },
  'tankers.waiting_minutes': { en: 'Waiting / Detention Time (Minutes)', ta: 'காத்திருப்பு நேரம் (நிமிடங்கள்)' },
  'tankers.waiting_rate_per_min': { en: 'Waiting Rate / Min (₹)', ta: 'காத்திருப்பு கட்டணம் / நிமிடம் (₹)' },
  'tankers.waiting_charge': { en: 'Waiting Surcharge (+₹)', ta: 'காத்திருப்பு கட்டணம் (+₹)' },
  'tankers.toll_charge': { en: 'Highway Toll / Gate Permit (+₹)', ta: 'டோல்கேட் / அனுமதி கட்டணம் (+₹)' },
  'tankers.system_calculated_bill': { en: 'Standard System Bill (Non-Negotiable)', ta: 'கணினி கணக்கிட்ட முறையான கட்டணம் (பேரம் பேச முடியாதது)' },
  'tankers.owner_discount': { en: 'Owner Approved Discount / Bargain Override (₹)', ta: 'உரிமையாளர் ஒப்புதல் அளித்த தள்ளுபடி (₹)' },
  'tankers.final_closing_amount': { en: 'Final Trip Closing Amount (₹)', ta: 'ட்ரிப் முடிவிற்கான இறுதி கட்டணம் (₹)' },
  'tankers.total_billing': { en: 'Total Trip Billing', ta: 'மொத்த ட்ரிப் கட்டணம்' },
  'tankers.driver_batta': { en: 'Driver Batta (₹)', ta: 'ஓட்டுனர் பட்டா (₹)' },
  'tankers.fuel_cost': { en: 'Fuel Cost (₹)', ta: 'எரிபொருள் செலவு (₹)' },
  'tankers.net_trip_profit': { en: 'Net Trip Profit', ta: 'ட்ரிப் நிகர லாபம்' },
  'tankers.telematics_map': { en: 'Live GPS Fleet Map & Geofences', ta: 'நேரடி GPS வரைபடம் & எல்லைகள்' },
  'tankers.recent_dispatches': { en: 'Recent Dispatches & Trip Slips', ta: 'சமீபத்திய ட்ரிப்புகள் & ரசீதுகள்' },

  // 20L Water Cans Portal
  'cans.title': { en: '20L Water Can Distribution', ta: '20லி வாட்டர் கேன் விநியோகம்' },
  'cans.subtitle': { en: 'Sequential plant refills, running stock counter, surprise audits, and route dwell tracking', ta: 'வரிசைமுறை பிளாண்ட் லோடுகள், நேரடி இருப்பு கணக்கு, திடீர் தணிக்கை, ஓய்வு நேர ஆய்வு' },
  'cans.multi_refills': { en: 'Multi-Plant Sequential Refills', ta: 'வரிசைமுறை பிளாண்ட் லோடு பதிவுகள்' },
  'cans.load_sequence': { en: 'Load Run', ta: 'லோடு எண்' },
  'cans.loaded_count': { en: 'Loaded Cans', ta: 'ஏற்றிய கேன்கள்' },
  'cans.delivered_count': { en: 'Delivered Cans', ta: 'விநியோகித்த கேன்கள்' },
  'cans.empty_returned': { en: 'Empty Returns', ta: 'திரும்பப் பெற்ற காலி கேன்கள்' },
  'cans.stock_on_truck': { en: 'Live Stock on Truck', ta: 'வண்டியில் மீதமுள்ள கேன்கள்' },
  'cans.cash_collected': { en: 'Cash in Hand', ta: 'ரொக்க வசூல்' },
  'cans.credit_issued': { en: 'Credit Issued', ta: 'கடன் விற்பனை' },
  'cans.net_margin': { en: 'Route Net Profit', ta: 'ரூட் நிகர லாபம்' },
  'cans.spot_audit_btn': { en: '🚨 Surprise Spot Audit', ta: '🚨 திடீர் களத் தணிக்கை (ஸ்பாட் ஆடிட்)' },
  'cans.record_refill_btn': { en: '+ Record Plant Refill', ta: '+ புதிய பிளாண்ட் லோடு சேர்' },
  'cans.dwell_analyzer': { en: 'Route Stoppage & Rest Dwell Analysis', ta: 'வாகனம் நின்ற இடங்கள் & ஓய்வு நேர ஆய்வு' },
  'cans.fuel_audit': { en: 'GPS vs Fuel Mileage Audit', ta: 'GPS தூரம் vs டீசல் மைலேஜ் சரிபார்ப்பு' },
  'cans.flagged_stop': { en: 'Unmapped Rest Stop > 30 Mins', ta: '30 நிமிடத்திற்கு மேல் நீண்ட ஓய்வு' },

  // Bakery & Retail Store Portal
  'bakery.title': { en: 'Bakery & Retail Store Counter', ta: 'பேக்கரி & சில்லறை கடை கல்லா' },
  'bakery.subtitle': { en: 'Open ingredient master, recurring templates, evening counter closing, and wastage counter', ta: 'விரிவான மூலப்பொருட்கள் பட்டியல், மாலை கல்லா கணக்கு, சேதாரக் கணக்கு' },
  'bakery.counter_closing': { en: '3-Minute Evening Counter Closing', ta: '3-நிமிட மாலை நேர கல்லா கணக்கு' },
  'bakery.drawer_cash': { en: 'Physical Drawer Notes (₹)', ta: 'கல்லாவில் உள்ள ரூபாய் நோட்டுகள் (₹)' },
  'bakery.drawer_coins': { en: 'Coins Tally (₹)', ta: 'சில்லறை நாணயங்கள் (₹)' },
  'bakery.drawer_expenses': { en: 'Expenses Paid from Drawer (₹)', ta: 'கல்லாவிலிருந்து கொடுத்த செலவுகள் (₹)' },
  'bakery.net_banked': { en: 'Net Cash Ready to Bank (₹)', ta: 'வங்கிக்கு செலுத்த வேண்டிய ரொக்கம் (₹)' },
  'bakery.upi_sales': { en: 'UPI Collections (GPay/PhonePe)', ta: 'UPI க்யூஆர் கோடு வசூல்' },
  'bakery.total_sales': { en: 'Total Counter Sales Today', ta: 'இன்றைய மொத்த விற்பனை' },
  'bakery.wastage_section': { en: 'Unsold Evening Wastage (Physical Counts)', ta: 'விற்பனையாகாத மாலை சேதாரம்' },
  'bakery.raw_materials': { en: 'Daily Raw Material Purchases (Open Master Catalog)', ta: 'தினசரி மூலப்பொருள் கொள்முதல் (முழு பட்டியல்)' },
  'bakery.add_purchase_btn': { en: '+ Add Raw Material Purchase', ta: '+ மூலப்பொருள் செலவு சேர்' },
  'bakery.recurring_templates': { en: 'Quick Add Recurring Ingredient', ta: 'விரைவு மூலப்பொருள் சேர்ப்பு' },

  // Mobile App Simulator
  'mobile.simulator_title': { en: 'Field Driver Mobile Terminal', ta: 'கள ஓட்டுனர் மொபைல் டெர்மினல்' },
  'mobile.ticket_mode': { en: 'Fast Delivery (<15s)', ta: 'வேகமான டெலிவரி (<15s)' },
  'mobile.trip_sheet_mode': { en: 'Tanker Trip Sheet', ta: 'டேங்கர் ட்ரிப் சீட்' },
  'mobile.plant_refill_mode': { en: 'Plant Refill & Photo Proof', ta: 'பிளாண்ட் லோடு & புகைப்படம்' },
  'mobile.customer_select': { en: 'Select Customer / Shop', ta: 'கடை அல்லது வாடிக்கையாளரை தேர்வு செய்க' },
  'mobile.cans_delivered': { en: 'Full Cans Delivered', ta: 'விநியோகித்த கேன்கள்' },
  'mobile.cans_returned': { en: 'Empty Cans Returned', ta: 'திரும்பிய காலி கேன்கள்' },
  'mobile.payment_mode': { en: 'Payment Mode', ta: 'பணம் செலுத்தும் முறை' },
  'mobile.cash': { en: 'Cash', ta: 'ரொக்கம்' },
  'mobile.upi': { en: 'UPI / GPay', ta: 'ஜிபே / UPI' },
  'mobile.credit': { en: 'Credit', ta: 'கடன்' },
  'mobile.confirm_btn': { en: 'CONFIRM DELIVERY (<15 SECONDS)', ta: 'டெலிவரியை உறுதி செய் (<15 வினாடிகள்)' },
  'mobile.gps_captured': { en: 'GPS Fix & Exact Seconds Captured', ta: 'GPS இருப்பிடம் மற்றும் வினாடி நேர முத்திரை பதிவானது' },
  'mobile.trip_number_today': { en: 'Plant Refill Run for Today', ta: 'இன்றைய பிளாண்ட் லோடு எண்' },
  'mobile.photo_attached': { en: 'Photo of Loaded Truck Attached', ta: 'லோடு செய்யப்பட்ட வண்டி புகைப்படம் இணைக்கப்பட்டது' },
  'mobile.anti_theft_note': { en: 'Location & seconds timestamp locked to prevent fraudulent activity', ta: 'மோசடிகளை தடுக்க இருப்பிடம் மற்றும் வினாடி நேர முத்திரை பூட்டப்பட்டது' },
  'mobile.odometer_at_plant': { en: 'Current Odometer (km)', ta: 'தற்போதைய கிலோமீட்டர் (கி.மீ)' }
};

// Word-by-word dynamic fallback dictionary for unmapped strings
export const dynamicWordDictionary: Record<string, string> = {
  'tanker': 'டேங்கர்',
  'lorry': 'லாரி',
  'lorries': 'லாரிகள்',
  'capacity': 'கொள்ளளவு',
  'dispatched': 'அனுப்பப்பட்டது',
  'dispatch': 'அனுப்புதல்',
  'running': 'ஓடுகிறது',
  'standby': 'தயார்நிலை',
  'active': 'செயலில்',
  'driver': 'ஓட்டுனர்',
  'vehicle': 'வாகனம்',
  'customer': 'வாடிக்கையாளர்',
  'trip': 'ட்ரிப்',
  'trips': 'ட்ரிப்புகள்',
  'diesel': 'டீசல்',
  'fuel': 'எரிபொருள்',
  'cash': 'ரொக்கம்',
  'credit': 'கடன்',
  'bank': 'வங்கி',
  'profit': 'லாபம்',
  'loss': 'நஷ்டம்',
  'revenue': 'வருவாய்',
  'expenses': 'செலவுகள்',
  'expense': 'செலவு',
  'margin': 'வரம்பு',
  'balance': 'இருப்பு',
  'total': 'மொத்தம்',
  'today': 'இன்று',
  'cans': 'கேன்கள்',
  'can': 'கேன்',
  'water': 'தண்ணீர்',
  'refill': 'லோடு',
  'plant': 'பிளாண்ட்',
  'intake': 'உள்வரவு',
  'delivery': 'விநியோகம்',
  'deliveries': 'விநியோகங்கள்',
  'audit': 'தணிக்கை',
  'dwell': 'தங்கிய நேரம்',
  'stoppage': 'நிறுத்தம்',
  'rest': 'ஓய்வு',
  'speed': 'வேகம்',
  'distance': 'தூரம்',
  'motor': 'மோட்டார்',
  'waiting': 'காத்திருப்பு',
  'toll': 'டோல்கேட்',
  'bakery': 'பேக்கரி',
  'store': 'கடை',
  'closing': 'கல்லா முடிவு',
  'drawer': 'கல்லாப்பெட்டி',
  'coins': 'சில்லறை நாணயங்கள்',
  'wastage': 'சேதாரம்',
  'purchase': 'கொள்முதல்',
  'purchases': 'கொள்முதல்கள்',
  'vendor': 'விற்பனையாளர்',
  'tax': 'வரி',
  'auditor': 'தணிக்கையாளர்',
  'cycle': 'சுழற்சி',
  'overdue': 'நிலுவை',
  'notes': 'ரூபாய் நோட்டுகள்',
  'bajji': 'பஜ்ஜி',
  'bonda': 'போண்டா',
  'puff': 'பப்ஸ்',
  'milk': 'பால் பாக்கெட்',
  'unbilled': 'பில் போடப்படாத',
  'corporate': 'நிறுவனம்',
  'odometer': 'கிலோமீட்டர் ரீடிங்'
};

/**
 * Universal Translation Function
 * @param keyOrText - Translation key or English raw text
 * @param lang - Target language ('en' | 'ta')
 * @param fallback - Optional English fallback string
 */
export function t(keyOrText: string, lang: Language = 'en', fallback?: string): string {
  // If English is requested, return the key/text or registered English string
  if (lang === 'en') {
    if (translations[keyOrText]?.en) {
      return translations[keyOrText].en;
    }
    return fallback || keyOrText;
  }

  // 1. Direct translation key lookup
  if (translations[keyOrText]?.ta) {
    return translations[keyOrText].ta;
  }

  // 2. Direct English value lookup (inverted search)
  for (const entry of Object.values(translations)) {
    if (entry.en.toLowerCase() === keyOrText.toLowerCase()) {
      return entry.ta;
    }
  }

  // 3. Word-by-word Tamil translation engine for dynamic feature extensions
  const words = keyOrText.split(/(\s+|[.,:;()/-])/);
  let hasTranslation = false;
  const translatedWords = words.map(part => {
    const cleanWord = part.toLowerCase().trim();
    if (dynamicWordDictionary[cleanWord]) {
      hasTranslation = true;
      return dynamicWordDictionary[cleanWord];
    }
    return part;
  });

  if (hasTranslation) {
    return translatedWords.join('');
  }

  // 4. Return original or fallback
  return fallback || keyOrText;
}

/**
 * Currency Formatter for Indian Rupees (₹)
 */
export function formatINR(amount: number): string {
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    maximumFractionDigits: 0
  }).format(amount).replace('₹', '₹ ');
}
