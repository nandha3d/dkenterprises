@php
    $sbCompanyId = session('company_id');
    $sbCompany = $sbCompanyId ? \App\Models\Company::find($sbCompanyId) : null;
    $sbIndustry = $sbCompany?->industry;
@endphp

{{-- DK Track Fleet Logistics & Operations Sidebar Group --}}
<li class="sidebar-heading"><span>DK Enterprises</span></li>
<li>
    <a href="#dktrack-menu" aria-expanded="true" data-toggle="collapse" class="text-primary font-weight-bold">
        <i class="dripicons-direction" style="color: #0284c7;"></i>
        <span>DK Track Fleet ERP</span>
    </a>
    <ul id="dktrack-menu" class="collapse list-unstyled show">
        <li>
            <a href="{{ route('dktrack.dashboard') }}">
                <i class="dripicons-meter"></i> Command Dashboard
            </a>
        </li>
        @if($sbIndustry !== 'packaged_water')
        <li>
            <a href="{{ route('dktrack.tankers') }}">
                <i class="dripicons-to-do"></i> Bulk Water Tankers
            </a>
        </li>
        @endif
        @if($sbIndustry !== 'bulk_water')
        <li>
            <a href="{{ route('dktrack.water_cans') }}">
                <i class="dripicons-drop"></i> Packaged Drinking Water &amp; Routes
            </a>
        </li>
        @endif
        <li>
            <a href="{{ route('dktrack.bakery') }}">
                <i class="dripicons-store"></i> Bakery &amp; Cafe Operations
            </a>
        </li>
        <li>
            <a href="{{ route('dktrack.customers') }}">
                <i class="dripicons-location"></i> Customers &amp; GPS Geo-Lock
            </a>
        </li>
        <li>
            <a href="{{ route('dktrack.telematics') }}">
                <i class="dripicons-map"></i> GPS Fleet Telematics
            </a>
        </li>
        <li>
            <a href="{{ route('dktrack.staff') }}">
                <i class="dripicons-user-group"></i> Staff, Drivers &amp; Payroll
            </a>
        </li>
        <li>
            <a href="{{ route('dktrack.mobile_simulator') }}" target="_blank">
                <i class="dripicons-phone"></i> Mobile Driver Portal
            </a>
        </li>
    </ul>
</li>
