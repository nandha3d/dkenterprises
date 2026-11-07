<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class ProductResource extends JsonResource
{
    public function toArray($request): array
    {
        $data = $this->resource->only([
            'id', 'name', 'print_name', 'code', 'type', 'barcode_symbology',
            'brand_id', 'category_id', 'unit_id', 'purchase_unit_id', 'sale_unit_id',
            'cost', 'profit_margin', 'profit_margin_type', 'price', 'wholesale_price',
            'qty', 'alert_quantity', 'daily_sale_objective', 'promotion', 'promotion_price',
            'starting_date', 'last_date', 'tax_id', 'tax_method', 'hsn_code', 'image',
            'is_batch', 'is_imei', 'is_variant', 'is_diffPrice', 'featured', 'product_details',
            'short_description', 'tags', 'meta_title', 'meta_description',
            'warranty', 'guarantee', 'warranty_type', 'guarantee_type',
            'in_stock', 'track_inventory', 'is_active', 'is_online',
            'kitchen_id', 'menu_type', 'extras', 'is_addon', 'variant_option', 'variant_value',
        ]);
        foreach (['category', 'brand', 'unit'] as $relation) {
            if ($this->resource->relationLoaded($relation)) $data[$relation] = $this->resource->$relation?->only(['id', 'name', 'unit_name', 'code']);
        }
        if ($this->resource->relationLoaded('productWarehouse')) {
            $data['product_warehouse'] = $this->resource->productWarehouse->map(fn ($stock) => $stock->only(['id', 'product_id', 'warehouse_id', 'variant_id', 'product_batch_id', 'qty'])
                + ['warehouse' => $stock->warehouse?->only(['id', 'name'])])->all();
        }
        return $data;
    }
}
