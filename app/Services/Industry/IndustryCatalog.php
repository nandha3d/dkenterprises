<?php

namespace App\Services\Industry;

/** Presets configure shared workflows; no industry-specific transaction master exists. */
final class IndustryCatalog
{
    public const SETTINGS = [
        'general_trading' => ['quantity_scale' => 4, 'units' => ['PCS'], 'labels' => [], 'reports' => []],
        'fmcg' => ['quantity_scale' => 4, 'units' => ['PCS', 'BOX', 'CASE'], 'picking' => 'fefo', 'expired_batch' => 'block',
            'master_defaults' => ['barcode', 'brand', 'hsn_code', 'gst', 'mrp', 'shelf_life_days', 'reorder_level'],
            'labels' => [], 'reports' => ['batch_expiry', 'reorder', 'route_distribution']],
        'textile' => ['quantity_scale' => 3, 'units' => ['MTR', 'KGS', 'DOZ', 'PCS'], 'uqc' => 'MTR',
            'labels' => ['warehouse' => 'Godown'],
            'document_fields' => ['transporter', 'lr_no', 'lr_date', 'bale_count', 'bundle_count'],
            'print' => ['lines' => 68, 'columns' => 80], 'entry_aids' => ['previous_rates' => true, 'outstanding' => true, 'clone_invoice' => true, 'inline_party' => true, 'inline_item' => true, 'tracking' => true],
            'reports' => ['stock_lot', 'previous_rates']],
        'timber' => ['quantity_scale' => 4, 'units' => ['PCS', 'CFT', 'CBM'], 'dimension_unit' => 'ft',
            'formula_version' => 'rectangular-v1', 'labels' => [], 'reports' => ['piece_volume', 'conversion_yield']],
        'solar' => ['quantity_scale' => 4, 'units' => ['PCS', 'KW'], 'labels' => ['project' => 'Site / Project'],
            'document_fields' => ['project_id', 'site_address'], 'reports' => ['project_margin', 'installed_serials', 'warranty_due']],
        'packaged_water' => [
            'quantity_scale' => 0,
            'units' => ['CAN', 'PCS', 'BOX', 'CASE', 'LTR'],
            'labels' => ['warehouse' => 'Bottling Plant / Yard', 'dispatch' => 'Route Delivery Sheet'],
            'master_defaults' => ['can_deposit', 'route_name', 'vehicle_no'],
            'reports' => ['route_distribution', 'can_deposit_ledger', 'gps_delivery_tracking'],
        ],
        'bulk_water' => [
            'quantity_scale' => 2,
            'units' => ['KL', 'LTR', 'TRIP', 'KM', 'MIN'],
            'labels' => ['warehouse' => 'Water Source / Borewell', 'dispatch' => 'Tanker Trip Sheet'],
            'master_defaults' => ['tanker_capacity_kl', 'vehicle_no', 'water_source', 'pump_rate_per_min', 'base_km_limit', 'excess_km_rate', 'waiting_rate_per_min'],
            'reports' => ['vehicle_logistics', 'tanker_trips', 'fleet_telematics'],
        ],
        'water_logistics' => [
            'quantity_scale' => 2,
            'units' => ['CAN', 'KL', 'LTR', 'TRIP', 'KM'],
            'labels' => ['warehouse' => 'Yard / Filling Station', 'dispatch' => 'Trip Sheet / Delivery Challan'],
            'master_defaults' => ['vehicle_no', 'tanker_capacity_kl', 'starting_km', 'ending_km', 'water_source'],
            'reports' => ['route_distribution', 'vehicle_logistics'],
        ],
        'cafe_bakery' => [
            'quantity_scale' => 3,
            'units' => ['PCS', 'KGS', 'GMS', 'LTR', 'CUP', 'BOX'],
            'labels' => ['warehouse' => 'Store / Kitchen Counter'],
            'master_defaults' => ['mrp', 'shelf_life_hours', 'batch_expiry'],
            'reports' => ['daily_drawer_reconciliation', 'ingredient_consumption'],
        ],
    ];

    /** Preset unit code => [name, other spellings that already count as this unit]. */
    public const UNITS = [
        'PCS' => ['Pieces', ['pc', 'piece', 'nos', 'no', 'unit']], 'BOX' => ['Box', ['bx']], 'CASE' => ['Case', ['cs']],
        'KGS' => ['Kilogram', ['kg', 'kilograms', 'kgs']], 'DOZ' => ['Dozen', ['dz', 'dozens']],
        'MTR' => ['Meter', ['m', 'mt', 'metre', 'meters', 'metres']], 'CFT' => ['Cubic feet', ['cu ft']],
        'CBM' => ['Cubic meter', ['m3', 'cubic metre']], 'KW' => ['Kilowatt', ['kilowatts']],
        'KL' => ['Kilolitre', ['kl', 'kilo litre', 'kilolitres']],
        'CAN' => ['20L Water Can', ['can', 'cans', '20l', '20l can']],
        'TRIP' => ['Trip', ['trips', 'trip sheet']],
        'KM' => ['Kilometer', ['km', 'kms', 'kilometre']],
        'LTR' => ['Litre', ['l', 'ltr', 'litres', 'liters']],
        'MIN' => ['Minute', ['min', 'mins', 'minutes']],
        'CUP' => ['Cup', ['cups']],
        'GMS' => ['Gram', ['g', 'gm', 'gms', 'grams']],
    ];

    public const ATTRIBUTES = [
        'general_trading' => [],
        'fmcg' => ['mrp' => ['MRP', 'number'], 'shelf_life_days' => ['Shelf life (days)', 'integer'], 'reorder_level' => ['Reorder level', 'number']],
        'textile' => ['fabric_type' => ['Fabric type', 'text'], 'construction' => ['Construction', 'text'], 'width' => ['Width', 'number'],
            'gsm' => ['GSM', 'number'], 'design' => ['Design', 'text'], 'color' => ['Color', 'text'], 'brand' => ['Brand', 'text'],
            'roll_lot' => ['Roll / lot', 'text'], 'rack_godown' => ['Rack / godown', 'text']],
        'timber' => ['species' => ['Species', 'text'], 'grade' => ['Grade', 'text'], 'moisture_class' => ['Moisture class', 'text'],
            'standard_dimensions' => ['Standard dimensions', 'text'], 'source' => ['Source', 'text']],
        'solar' => ['wattage' => ['Wattage', 'number'], 'voltage' => ['Voltage', 'number'], 'phase' => ['Phase', 'text'],
            'panel_type' => ['Panel type', 'text'], 'inverter_type' => ['Inverter type', 'text'], 'warranty_months' => ['Warranty (months)', 'integer']],
        'packaged_water' => [
            'can_deposit' => ['Security Deposit per Can (₹)', 'number'],
            'route_name' => ['Default Route / Beat', 'text'],
            'vehicle_no' => ['Delivery Vehicle Reg No (Tata Ace)', 'text'],
            'geofence_lock' => ['GPS Geofence Lock Required (1/0)', 'number'],
        ],
        'bulk_water' => [
            'vehicle_no' => ['Tanker Registration No', 'text'],
            'tanker_capacity_kl' => ['Tanker Capacity (KL)', 'number'],
            'water_source' => ['Borewell / Source Plant', 'text'],
            'pump_rate_per_min' => ['Motor Pumping Rate (₹/min)', 'number'],
            'base_km_limit' => ['Base Minimum Distance (KM)', 'number'],
            'excess_km_rate' => ['Excess Distance Charge (₹/KM)', 'number'],
            'waiting_rate_per_min' => ['Waiting Charge (₹/min)', 'number'],
        ],
        'water_logistics' => [
            'vehicle_no' => ['Vehicle Registration No', 'text'],
            'tanker_capacity_kl' => ['Tanker Capacity (KL)', 'number'],
            'water_source' => ['Water Source / Borewell Location', 'text'],
            'can_deposit' => ['Security Deposit per Can (₹)', 'number'],
        ],
        'cafe_bakery' => [
            'shelf_life_hours' => ['Shelf Life (Hours)', 'integer'],
            'serving_type' => ['Serving Type (Hot/Cold/Baked)', 'text'],
            'recipe_yield' => ['Recipe Output Multiplier', 'number'],
        ],
    ];

    // Process thresholds are explicit presets. Users configure their actual process before dispatch.
    public const PROCESSES = [
        // Grey → dyed fabric is a conversion (a new item comes back); the others return the same material.
        'textile' => [['BLEACHING', 'Bleaching', 0, false], ['GREY-DYE', 'Dyeing - grey to dyed fabric', 5, true], ['DYEING', 'Dyeing', 4, false], ['PRINTING', 'Printing', 4, false], ['FINISHING', 'Finishing', 4, false]],
        'timber' => [['SAWING', 'External sawing', 30, true]],
        'fmcg' => [['REPACKING', 'Outsourced repacking', 5, true]],
        'packaged_water' => [['BOTTLING', 'Water Purification, Filling & Capping', 0, false]],
        'bulk_water' => [['WATER-PUMP', 'Source Pumping & Tanker Filling', 0, false]],
        'water_logistics' => [['WATER-PUMP', 'Source Pumping & Tanker Filling', 0, false]],
        'cafe_bakery' => [['BAKING', 'Kitchen Baking & Preparation', 0, true]],
    ];

    /**
     * Capabilities a business type adds on top of its profile preset. Applying a profile resets to the preset first,
     * so switching type also hides what the previous type added. The first type is the default.
     */
    public const SUBTYPES = [
        'general_trading' => ['trading' => []],
        'fmcg' => ['distribution' => [], 'manufacturer' => ['manufacturing.bom', 'manufacturing.production'], 'route_distribution' => ['sales.route_distribution']],
        'packaged_water' => [
            'can_route_distribution' => ['sales.route_distribution', 'operations.water_logistics'],
            'wholesale_beverage' => ['sales.wholesale', 'operations.water_logistics'],
        ],
        'bulk_water' => [
            'commercial_tankers' => ['operations.water_logistics'],
            'emergency_supply' => ['operations.water_logistics'],
        ],
        'water_logistics' => [
            'bulk_tankers' => ['operations.water_logistics'],
            'can_distribution' => ['sales.route_distribution', 'operations.water_logistics'],
            'integrated_logistics' => ['sales.route_distribution', 'operations.water_logistics'],
        ],
        'cafe_bakery' => [
            'cafe_pos' => ['sales.pos', 'operations.cafe_bakery'],
            'bakery_production' => ['sales.pos', 'operations.cafe_bakery', 'manufacturing.bom', 'manufacturing.production'],
        ],
        // Traders buy finished cloth and sell it on; only manufacturing sends material out for processing or makes goods.
        'textile' => ['wholesale_distributor' => ['sales.route_distribution'], 'wholesale' => [], 'distributor' => ['sales.route_distribution'],
            'manufacturing' => ['operations.job_work', 'manufacturing.bom', 'manufacturing.production']],
        'timber' => ['trading' => [], 'processor' => ['manufacturing.bom', 'manufacturing.production', 'operations.job_work']],
        'solar' => ['epc' => []],
    ];

    public const SUBTYPE_LABELS = [
        'wholesale_distributor' => 'Wholesale & Distributor',
        'can_route_distribution' => '20L Can Daily Route Distribution (Tata Ace)',
        'wholesale_beverage' => 'Wholesale Canned & Bottled Distribution',
        'commercial_tankers' => 'Commercial Bulk Water Supply (40KL+ Tankers)',
        'emergency_supply' => 'Emergency & Construction Tanker Supply',
        'bulk_tankers' => 'Bulk Water Tankers (40KL+)',
        'can_distribution' => '20L Water Cans Route Distribution',
        'integrated_logistics' => 'Integrated Fleet & Tankers',
        'cafe_pos' => 'Cafe Counter POS & Daily Float',
        'bakery_production' => 'Bakery Production & Store Counter',
    ];

    /** Business type settings replace the profile's top-level setting of the same key. */
    public const SUBTYPE_SETTINGS = [
        'textile' => ['manufacturing' => [
            'labels' => ['dispatch' => 'Material DC', 'receipt' => 'Job Work GRN', 'warehouse' => 'Godown'],
            'reports' => ['job_work_pending', 'job_work_shrinkage', 'stock_lot', 'previous_rates'],
        ]],
    ];

    /** Profile attributes a business type does not use; saved values are kept. Brand distributors do not deal in mill specs. */
    public const SUBTYPE_HIDDEN_ATTRIBUTES = [
        'textile' => ['distributor' => ['construction', 'gsm']],
    ];

    public static function subtypeLabel(?string $subtype): string
    {
        return self::SUBTYPE_LABELS[$subtype] ?? ucwords(str_replace('_', ' ', (string) $subtype));
    }

    public static function settings(string $profile, ?string $subtype): array
    {
        return array_replace(self::SETTINGS[$profile], self::SUBTYPE_SETTINGS[$profile][$subtype] ?? []);
    }
}
