// ignore: file_names
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:front_flutter_api_rest/src/model/productoModel.dart';
import 'package:http/http.dart' as http;
import 'package:front_flutter_api_rest/src/providers/provider.dart';

class ProductoController {
  Future<List<dynamic>> getDataProductos({String? nombre}) async {
    try {
      final urls = Providers.provider();
      String urlString = urls['productoListProvider']!;

      if (nombre != null && nombre.isNotEmpty) {
        urlString += '/buscar?nombre=$nombre';
      }

      final url = Uri.parse(urlString);
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

  Future<http.Response> crearProducto(ProductoModel nuevoProducto) async {
    final urls = Providers.provider();
    final urlString = urls['productoListProvider']!;
    final url = Uri.parse(urlString);

    final body = jsonEncode(nuevoProducto.toJson());

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Producto creado: ${response.body}');
    } else {
      print(
          'Error al crear producto: ${response.statusCode} - ${response.body}');
    }
    return response;
  }

  Future<http.Response> editarProducto(ProductoModel productoEditado) async {
    final urls = Providers.provider();
    final urlString = urls['productoListProvider']!;
    final url = Uri.parse(urlString);

    final body = jsonEncode(productoEditado.toJson());

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      print('producto editado: ${response.body}');
    } else {
      print(
          'Error al editar producto: ${response.statusCode} - ${response.body}');
    }

    return response;
  }

  Future<http.Response> removeProducto(int id, String fotoURL) async {
    final urls = Providers.provider();
    final urlString = urls['productoListProvider']!;
    final url = Uri.parse('$urlString/$id');

    var response = await http.delete(
      url,
      headers: {"Content-Type": "application/json"},
    );
   
    if (fotoURL.isNotEmpty &&
        (fotoURL.startsWith('gs://') || fotoURL.startsWith('https://'))) {
   
      try {
        await FirebaseStorage.instance.refFromURL(fotoURL).delete();
        print("Imagen eliminada de Firebase Storage");
      } catch (e) {
        print("Error al eliminar la imagen: $e");
      }
    }

    print("Status Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    // if (response.statusCode == 200 || response.statusCode == 204) {
    //   print('Producto eliminado con exito: ${response.body}');
    // }
    return response;
  }
}
