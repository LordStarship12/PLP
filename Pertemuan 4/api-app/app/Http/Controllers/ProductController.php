<?php

namespace App\Http\Controllers;

use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class ProductController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $products = Product::all();
        return response()->json(['message' => 'Successfully loaded all the products.', 'data' => $products], 200);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        try {
            $request->validate([
                'name' => 'required|string|unique:products,name',
                'price' => 'required|integer',
                'photo' => 'required|string',
                'is_promo' => 'required|boolean',
            ]);

            // $imgPath = $request->file('photo')->store('img', options: 'public');
            // $imgPath = str_replace('public/', 'storage/', $imgPath);
            
            $product = Product::create([
                'name' => $request->name,
                'price' => $request->price,
                'photo' => $request->photo,
                'is_promo' => $request->is_promo,
            ]);
            return response()->json(['message' => 'Successfully created the product.', 'product' => $product], 201);
        } catch (\Exception $e) {
            Log::error('Error creating the product', ['message' => $e->getMessage()]);
            return response()->json(['error' => 'Failed to create product'], 404);
        }
    }

    /**
     * Display the specified resource.
     */
    public function show($id)
    {
        try {
            $product = Product::findOrFail($id);
            return response()->json(['message' => 'Successfully loaded the product.', 'product' => $product], 200);
        } catch (\Exception $e) {
            Log::error('Error loading the product', ['message' => $e->getMessage()]);
            return response()->json(['error' => 'Failed to load product'], 404);
        }
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, $id)
    {
        try {
            $product = Product::findOrFail($id);

            $request->validate([
                'name' => 'string|unique:products,name,' . $product->id,
                'price' => 'integer',
                'photo' => 'string',
                'is_promo' => 'boolean',
            ]);

            // if ($request->hasFile('photo')) {
            //     $imgPath = $request->file('photo')->store('img', options: 'public');
            //     $imgPath = str_replace('public/', 'storage/', $imgPath);
            // }

            $product->update([
                'name' => $request->name ?? $product->name,
                'price' => $request->price ?? $product->price,
                'photo' => $request->photo ?? $product->photo,
                'is_promo' => $request->is_promo ?? $product->is_promo,
            ]);

            $product->save();
            return response()->json(['message' => 'Successfully updated the product.', 'product' => $product], 200);
        } catch (\Exception $e) {
            Log::error('Error updating the product', ['message' => $e->getMessage()]);
            return response()->json(['error' => 'Failed to update product'], 404);
        }
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy($id)
    {
        try {
            $product = Product::findOrFail($id);
            $product->delete();
            return response()->json(['message' => 'Successfully deleted the product.'], 200);
        } catch (\Exception $e) {
            Log::error('Error deleting the product', ['message' => $e->getMessage()]);
            return response()->json(['error' => 'Failed to delete product'], 404);
        }
    }
}
