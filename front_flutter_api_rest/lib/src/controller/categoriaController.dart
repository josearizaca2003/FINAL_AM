import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:front_flutter_api_rest/src/model/categoriaModel.dart';
import 'package:front_flutter_api_rest/src/providers/provider.dart';
import 'package:front_flutter_api_rest/src/services/sheet_exel.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter/services.dart' show rootBundle;


class CategoriaController {
  static const _scopes = [SheetsApi.spreadsheetsScope];
  final _sheetName = 'Sheet1';
  final String _spreadsheetId = ExelSheet.categoriaSheet;
 
  Future<AutoRefreshingAuthClient> _getAuthClient() async {
    final credentialsJson =
        await rootBundle.loadString('assets/credencial_sheet.json');
    final accountCredentials =
        ServiceAccountCredentials.fromJson(json.decode(credentialsJson));
    return clientViaServiceAccount(accountCredentials, _scopes);
  }

  Future<void> setupSheet() async {
    final authClient = await _getAuthClient();
    final sheetsApi = SheetsApi(authClient);

    // Establecer el encabezado
    final headerRow = [
      'ID',
      'Nombre',
      'tag',
      'estado',
      'Imagen'
    ]; // Nombres de las columnas
    await _updateRow(0, headerRow);

    // Crear solicitud para agregar datos a la hoja de cálculo
    final formatRequest = BatchUpdateSpreadsheetRequest.fromJson({
      'requests': [
        {
          'updateCells': {
            'rows': [
              {
                'values': [
                  {
                    'userEnteredValue': {
                      'stringValue':
                          _spreadsheetId, // Asumiendo que este es el valor que quieres agregar
                    },
                  },
                ],
              },
            ],
            'range': {
              'sheetId': 0, // Asumiendo que es la primera hoja
              'startRowIndex': 1, // Segunda fila
              'startColumnIndex': 0,
              'endColumnIndex': 1,
            },
            'fields': 'userEnteredValue',
          },
        },
      ],
    });

    await sheetsApi.spreadsheets.batchUpdate(formatRequest, _spreadsheetId);
  }

  Future<void> listarCat() async {
    final authClient = await _getAuthClient();
    final sheetsApi = SheetsApi(authClient);

    final range = '$_sheetName!A1:G'; // Asumiendo que hay 7 columnas A a G

    try {
      ValueRange response =
          await sheetsApi.spreadsheets.values.get(_spreadsheetId, range);
      List<List<dynamic>> values = response.values!;

      if (values.isEmpty) {
        print('No hay items registrados.');
      } else {
        print('Items Registrados:');
        values.forEach((row) {
          print(' - ${row.join(', ')}');
        });
      }
    } catch (e) {
      print('Error al obtener eventos desde Google Sheets: $e');
    }
  }

  Future<void> _addRow(List<String> row) async {
    final authClient = await _getAuthClient();
    final sheetsApi = SheetsApi(authClient);
    final range = '$_sheetName!A1';

    ValueRange vr = ValueRange.fromJson({
      'values': [row]
    });

    await sheetsApi.spreadsheets.values
        .append(vr, _spreadsheetId, range, valueInputOption: 'RAW');
  }

  Future<void> _updateRow(int rowIndex, List<String> row) async {
    final authClient = await _getAuthClient();
    final sheetsApi = SheetsApi(authClient);
    final range = '$_sheetName!A${rowIndex + 1}';

    ValueRange vr = ValueRange.fromJson({
      'values': [row]
    });

    await sheetsApi.spreadsheets.values
        .update(vr, _spreadsheetId, range, valueInputOption: 'RAW');
  }

  Future<void> _deleteRow(int rowIndex) async {
    final authClient = await _getAuthClient();
    final sheetsApi = SheetsApi(authClient);

    try {
      Spreadsheet spreadsheet =
          await sheetsApi.spreadsheets.get(_spreadsheetId);
      Sheet sheet = spreadsheet.sheets![0];

      BatchUpdateSpreadsheetRequest batchUpdateRequest =
          BatchUpdateSpreadsheetRequest.fromJson({
        'requests': [
          {
            'deleteDimension': {
              'range': {
                'sheetId': sheet.properties!.sheetId!,
                'dimension': 'ROWS',
                'startIndex': rowIndex,
                'endIndex': rowIndex + 1
              }
            }
          }
        ]
      });

      await sheetsApi.spreadsheets
          .batchUpdate(batchUpdateRequest, _spreadsheetId);
    } catch (e) {
      print('Error al eliminar fila desde Google Sheets: $e');
    }
  }

  Future<List<dynamic>> getDataCategories({String? nombre}) async {
  try {
    final urls = Providers.provider();
    String urlString = urls['categoriaListProvider']!;

    // Si el nombre es proporcionado, lo agregamos como parámetro de búsqueda
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

  Future<http.Response> crearCategoria(CategoriaModel nuevaCategoria) async {
    // Obtener la URL del proveedor
    final urls = Providers.provider();
    final urlString = urls['categoriaListProvider']!;
    final url = Uri.parse(urlString);

    // Crear el cuerpo de la solicitud
    final body = jsonEncode(nuevaCategoria.toJson());

    // Enviar la solicitud POST
    final response = await http.post(
      url,
      headers: {
        'Content-Type':
            'application/json', // Especificar que el contenido es JSON
      },
      body: body,
    );

    // Manejar la respuesta
    if (response.statusCode == 200 || response.statusCode == 201) {
      // La categoría se creó con éxito
      print('Categoría creada: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _addRow([
          nuevaCategoria.nombre.toString(),
          nuevaCategoria.tag.toString(),
          nuevaCategoria.estado.toString(),
          nuevaCategoria.foto.toString()
        ]);
      }
    } else {
      // Ocurrió un error
      print(
          'Error al crear categoría: ${response.statusCode} - ${response.body}');
    }

    return response; // Retornar la respuesta
  }

  Future<http.Response> editarCategoria(CategoriaModel categoriaEditada) async {
    // Obtener la URL del proveedor
    final urls = Providers.provider();
    final urlString = urls['categoriaListProvider']!;
    final url =
        Uri.parse(urlString); // URL sin ID, ya que se enviará en el cuerpo

    // Crear el cuerpo de la solicitud, incluyendo el ID
    final body = jsonEncode(categoriaEditada.toJson());

    // Enviar la solicitud PUT
    final response = await http.put(
      url,
      headers: {
        'Content-Type':
            'application/json', // Especificar que el contenido es JSON
      },
      body: body,
    );

     // Manejar la respuesta
    if (response.statusCode == 200 || response.statusCode == 204) {
      // La categoría se actualizó con éxito
      print('Categoría editada: ${response.body}');

      await _updateRow(categoriaEditada.id!, [ 
        categoriaEditada.nombre ?? '',
        categoriaEditada.tag ?? '',
        categoriaEditada.estado ?? '',
        categoriaEditada.foto ?? ''
      ]);
    } else {
 
      print('Error al editar categoría: ${response.statusCode} - ${response.body}');
    }


    return response; // Retornar la respuesta
  }

  Future<http.Response> removeCategoria(int id, String fotoURL) async {
    final urls = Providers.provider();
    final urlString = urls['categoriaListProvider']!;
    final url = Uri.parse('$urlString/$id');

    var response = await http.delete(
      url,
      headers: {"Content-Type": "application/json"},
    );
    // Verifica si la fotoURL es una URL válida de Firebase Storage
    if (fotoURL.isNotEmpty &&
        (fotoURL.startsWith('gs://') || fotoURL.startsWith('https://'))) {
      // Elimina la foto de Firebase Storage
      try {
        await FirebaseStorage.instance.refFromURL(fotoURL).delete();
        print("Imagen eliminada de Firebase Storage");
      } catch (e) {
        print("Error al eliminar la imagen: $e");
      }
    }

    print("Status Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 204) {
      await _deleteRow(id);
    }
    return response;
  }
}
