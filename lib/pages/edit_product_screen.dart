import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/product_db.dart';
import '../models/product.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _description;
  late double _price;
  late String _category;
  File? _image;
  final List<String> _categories = const ["Shoes", "Pants", "Shirts", "Bags", "Jackets"];

  @override
  void initState() {
    super.initState();
    _name = widget.product.name;
    _description = widget.product.description;
    _price = widget.product.price;
    _category = widget.product.category.isNotEmpty ? widget.product.category : _categories.first;
    if (widget.product.imageUrl.isNotEmpty) {
      _image = File(widget.product.imageUrl);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final updatedProduct = Product(
        id: widget.product.id,
        name: _name,
        description: _description,
        price: _price,
        category: _category,
        imageUrl: _image?.path ?? widget.product.imageUrl,
        isFavorite: widget.product.isFavorite,
        isSold: widget.product.isSold,
        discount: widget.product.discount,
      );

      await DatabaseHelper.instance.updateProduct(updatedProduct);
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Edit Product"),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.purple[100],
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
              child: ListView(
                shrinkWrap: true,
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
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : (widget.product.imageUrl.isNotEmpty
                                  ? Image.file(
                                      File(widget.product.imageUrl),
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      height: 200,
                                      color: Colors.grey[300],
                                    )),
                          Container(
                            height: 200,
                            color: Colors.black26,
                            child: const Center(
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    initialValue: _name,
                    decoration: InputDecoration(
                      labelText: 'Product Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.label),
                    ),
                    validator: (value) => (value == null || value.isEmpty) ? 'Enter name' : null,
                    onChanged: (value) => _name = value,
                  ),
                  const SizedBox(height: 15),

                  TextFormField(
                    initialValue: _description,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.description),
                    ),
                    validator: (value) => (value == null || value.isEmpty) ? 'Enter description' : null,
                    onChanged: (value) => _description = value,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 15),

                  TextFormField(
                    initialValue: _price.toString(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Price',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                    validator: (value) => (value == null || double.tryParse(value) == null)
                        ? 'Enter valid price'
                        : null,
                    onChanged: (value) => _price = double.parse(value),
                  ),
                  const SizedBox(height: 15),

                  DropdownButtonFormField<String>(
                    value: _categories.contains(_category) ? _category : _categories.first,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.category),
                    ),
                    items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                    onChanged: (value) => setState(() => _category = value!),
                  ),
                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                      ),
                      onPressed: _saveChanges,
                      child: const Text('Save Changes', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
