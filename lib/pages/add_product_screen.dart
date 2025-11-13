import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/product_db.dart';
import '../models/product.dart';

class AddProductScreen extends StatefulWidget {
  final VoidCallback onProductAdded;
  const AddProductScreen({super.key, required this.onProductAdded});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountController = TextEditingController();

  bool hasDiscount = false;
  File? _image;

  final List<String> _categories = [
    'Shoes',
    'Pants',
    'Shirts',
    'Bags',
    'Jackets',
  ];
  String? _selectedCategory;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate() && _image != null && _selectedCategory != null) {
      final newProduct = Product(
        name: _nameController.text,
        imageUrl: _image!.path,
        price: double.parse(_priceController.text),
        description: _descriptionController.text,
        discount: hasDiscount ? int.tryParse(_discountController.text) ?? 0 : 0,
        isSold: false,
        isFavorite: false,
        category: _selectedCategory!.toLowerCase(),
      );

      await DatabaseHelper.instance.insertProduct(newProduct);
      widget.onProductAdded();
      if (!mounted) return;
      Navigator.pop(context);

      final all = await DatabaseHelper.instance.getProducts();
      // ignore: avoid_print
      print('All products in DB: ${all.map((p) => p.name).toList()}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all fields, select a category and add an image'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Add New Product'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _image != null
                                ? Image.file(
                                    _image!,
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    height: 180,
                                    width: double.infinity,
                                    color: Colors.grey[300],
                                  ),
                            Container(
                              height: 180,
                              color: Colors.black26,
                              child: const Center(
                                child: Icon(Icons.camera_alt, color: Colors.white, size: 40),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Product Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.label),
                      ),
                      validator: (value) => (value == null || value.isEmpty) ? 'Enter product name' : null,
                    ),
                    const SizedBox(height: 15),

                    const Text(
                      'Select Category',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories.map((category) {
                          final isSelected = _selectedCategory == category;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(category),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() => _selectedCategory = selected ? category : null);
                              },
                              selectedColor: Colors.blueAccent.withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.blueAccent : Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                              backgroundColor: Colors.grey[200],
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.description),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => (value == null || value.isEmpty) ? 'Enter price' : null,
                    ),
                    const SizedBox(height: 15),

                    SwitchListTile(
                      title: const Text('Apply Discount?'),
                      value: hasDiscount,
                      onChanged: (val) => setState(() => hasDiscount = val),
                    ),
                    if (hasDiscount)
                      TextFormField(
                        controller: _discountController,
                        decoration: InputDecoration(
                          labelText: 'Discount (%)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.percent),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                        ),
                        onPressed: _saveProduct,
                        child: const Text('Save Product', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
