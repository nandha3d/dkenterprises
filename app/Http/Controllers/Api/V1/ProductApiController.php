<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class ProductApiController extends BaseApiController
{
    public function metadata(Request $request): JsonResponse
    {
        $context = $this->companyContext($request);
        $companyId = $context->companyId;

        $categories = \App\Models\Category::where('is_active', true)
            ->when($companyId, fn ($q) => $q->where('company_id', $companyId))
            ->select('id', 'name', 'parent_id', 'default_hsn_code')
            ->get();

        $brands = \App\Models\Brand::where('is_active', true)
            ->when($companyId, fn ($q) => $q->where('company_id', $companyId))
            ->select('id', 'title as name', 'image')
            ->get();

        $units = \App\Models\Unit::where('is_active', true)
            ->when($companyId, fn ($q) => $q->where('company_id', $companyId))
            ->select('id', 'unit_name', 'unit_code', 'operator', 'operation_value')
            ->get();

        $taxes = \App\Models\Tax::where('is_active', true)
            ->when($companyId, fn ($q) => $q->where('company_id', $companyId))
            ->select('id', 'name', 'rate')
            ->get();

        $warehouses = \App\Models\Warehouse::where('is_active', true)
            ->when($companyId, fn ($q) => $q->where('company_id', $companyId))
            ->select('id', 'name', 'address', 'phone')
            ->get();

        return $this->sendResponse([
            'categories' => $categories,
            'brands' => $brands,
            'units' => $units,
            'taxes' => $taxes,
            'warehouses' => $warehouses,
            'types' => ['standard', 'combo', 'digital', 'service'],
            'barcode_symbologies' => ['C128', 'C39', 'UPCA', 'UPCE', 'EAN8', 'EAN13'],
            'tax_methods' => [
                ['id' => 1, 'name' => 'Exclusive'],
                ['id' => 2, 'name' => 'Inclusive'],
            ],
            'profit_margin_types' => ['percentage', 'fixed'],
            'usage_types' => ['composite', 'sale', 'purchase'],
        ], 'Product configuration metadata retrieved successfully');
    }

    public function index(Request $request): JsonResponse
    {
        $request->validate(['per_page' => 'sometimes|integer|min:1|max:100', 'search' => 'nullable|string|max:100']);
        $query = Product::catalogFor($this->companyContext($request));

        if ($request->filled('category_id')) {
            $query->where('category_id', $request->category_id);
        }
        if ($request->filled('brand_id')) {
            $query->where('brand_id', $request->brand_id);
        }
        if ($request->filled('search')) {
            $term = $request->search;
            $query->where(function ($q) use ($term) {
                $q->where('name', 'LIKE', "%{$term}%")
                  ->orWhere('code', 'LIKE', "%{$term}%");
            });
        }

        $perPage = (int) $request->input('per_page', 20);
        $products = $query->where('is_active', true)->paginate($perPage);

        return $this->sendResponse(\App\Http\Resources\ProductResource::collection($products->getCollection())->resolve($request), 'Products retrieved successfully', 200, [
            'pagination' => [
                'total' => $products->total(),
                'per_page' => $products->perPage(),
                'current_page' => $products->currentPage(),
                'last_page' => $products->lastPage(),
            ]
        ]);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $context = $this->companyContext($request);
        $product = Product::catalogFor($context)->with([
            'productWarehouse' => fn ($q) => $q->visibleIn($context)->with([
                'warehouse' => fn ($w) => $w->forCompany($context)->where('branch_id', $context->branchId),
            ]),
        ])->find($id);

        if (!$product) {
            return $this->sendError('Product not found', [], 404);
        }

        return $this->sendResponse((new \App\Http\Resources\ProductResource($product))->resolve($request), 'Product retrieved successfully');
    }

    public function search(Request $request, string $term): JsonResponse
    {
        validator(['term' => $term], ['term' => 'required|string|max:100'])->validate();
        $products = Product::catalogFor($this->companyContext($request), ['products.id', 'products.name', 'products.code', 'products.price', 'products.cost', 'products.image'])
            ->where('is_active', true)
            ->where(function ($q) use ($term) {
                $q->where('name', 'LIKE', "%{$term}%")
                  ->orWhere('code', 'LIKE', "%{$term}%");
            })
            ->limit(20)
            ->get();

        return $this->sendResponse(\App\Http\Resources\ProductResource::collection($products)->resolve($request), 'Search results');
    }

    public function store(Request $request): JsonResponse
    {
        $context = $this->companyContext($request);
        $request->validate([
            'name' => 'required|string|max:255',
            'code' => 'required|string|max:100',
            'type' => 'sometimes|string|in:standard,combo,digital,service',
            'price' => 'required|numeric|min:0',
            'cost' => 'required|numeric|min:0',
            'category_id' => 'sometimes|nullable|integer',
            'brand_id' => 'sometimes|nullable|integer',
            'unit_id' => 'sometimes|nullable|integer',
        ]);

        $data = $request->all();
        $data['company_id'] = $context->companyId;
        $data['branch_id'] = $context->branchId;
        $data['is_active'] = $request->boolean('is_active', true);
        $data['in_stock'] = $request->boolean('in_stock', true);
        $data['track_inventory'] = $request->boolean('track_inventory', true);

        // Ensure unique code per company
        $existing = Product::forCompany($context)->where('code', $data['code'])->first();
        if ($existing) {
            return $this->sendError('Product code / SKU already exists in this company.', [], 422);
        }

        $product = Product::create($data);

        // Initial warehouse stock if provided
        if ($request->filled('initial_stock') && $request->filled('warehouse_id')) {
            $qty = (float) $request->input('initial_stock', 0);
            if ($qty > 0) {
                \App\Models\Product_Warehouse::create([
                    'product_id' => $product->id,
                    'warehouse_id' => $request->input('warehouse_id'),
                    'qty' => $qty,
                    'price' => $product->price,
                    'company_id' => $context->companyId,
                    'branch_id' => $context->branchId,
                ]);
            }
        }

        return $this->sendResponse((new \App\Http\Resources\ProductResource($product))->resolve($request), 'Product created successfully', 201);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $context = $this->companyContext($request);
        $product = Product::forCompany($context)->find($id);
        if (!$product) {
            return $this->sendError('Product not found in this company.', [], 404);
        }

        $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'code' => 'sometimes|required|string|max:100',
            'price' => 'sometimes|required|numeric|min:0',
            'cost' => 'sometimes|required|numeric|min:0',
        ]);

        $data = $request->except(['id', 'company_id']);
        if ($request->has('is_active')) {
            $data['is_active'] = $request->boolean('is_active');
        }
        if ($request->has('in_stock')) {
            $data['in_stock'] = $request->boolean('in_stock');
        }
        if ($request->has('track_inventory')) {
            $data['track_inventory'] = $request->boolean('track_inventory');
        }

        $product->update($data);

        return $this->sendResponse((new \App\Http\Resources\ProductResource($product))->resolve($request), 'Product updated successfully');
    }
}
