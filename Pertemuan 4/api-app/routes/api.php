<?php

use App\Http\Controllers\ProductController;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

// Route::get('/products', function () {
//     return response()->json([
//         ['id' => 1, 'name' => 'Mango Sagoo', 'price' => 25000, 'photo' => 'https://images.pexels.com/photos/31173340/pexels-photo-31173340/free-photo-of-delicious-asian-cuisine-in-bamboo-steamer.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'is_promo' => true],
//         ['id' => 2, 'name' => 'Nasi Kuning', 'price' => 15000, 'photo' => 'https://images.pexels.com/photos/3992196/pexels-photo-3992196.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'is_promo' => false]
//     ]);
// });

Route::resource('products', ProductController::class);
