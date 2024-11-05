// ignore: file_names
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:front_flutter_api_rest/src/model/productoModel.dart';
import 'package:front_flutter_api_rest/src/model/subCategoriaModel.dart';
import 'package:http/http.dart' as http;
import 'package:front_flutter_api_rest/src/providers/provider.dart';

class SubCategoriaController {
  Future<List<dynamic>> getDataSubCategoria({String? nombre}) async {
    try {
      final urls = Providers.provider();
      String urlString = urls['subCategoriaListProvider']!;

      if (nombre != null && nombre.isNotEmpty) {
        urlString += '/buscar?nombre=$nombre';
      }

      final url = Uri.parse(urlString);
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load subcategories');
      }
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

  Future<http.Response> crearSubCategoria(SubCategoriaModel nuevaSubCategoria) async {
    final urls = Providers.provider();
    final urlString = urls['subCategoriaListProvider']!;
    final url = Uri.parse(urlString);

    final body = jsonEncode(nuevaSubCategoria.toJson());

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('subcategoria creado: ${response.body}');
    } else {
      print(
          'Error al crear subcategoria: ${response.statusCode} - ${response.body}');
    }
    return response;
  }

  Future<http.Response> editarSubCategoria(SubCategoriaModel subCategoriaEditado) async {
    final urls = Providers.provider();
    final urlString = urls['subCategoriaListProvider']!;
    final url = Uri.parse(urlString);

    final body = jsonEncode(subCategoriaEditado.toJson());

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      print('subcategoria editado: ${response.body}');
    } else {
      print(
          'Error al editar subcategoria: ${response.statusCode} - ${response.body}');
    }

    return response;
  }

  Future<http.Response> removeSubCategoria(int id, String fotoURL) async {
    final urls = Providers.provider();
    final urlString = urls['subCategoriaListProvider']!;
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
