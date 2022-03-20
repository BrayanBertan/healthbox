import 'package:healthbox/app/data/enums/genero.dart';
import 'package:healthbox/app/data/enums/tipo_usuario.dart';
import 'package:healthbox/app/data/models/usuario.dart';

class Paciente extends Usuario {
  double altura;
  double peso;
  String cpf;

  Paciente(
      {required this.altura,
      required this.peso,
      required this.cpf,
      int? id,
      required TipoUsuario tipo,
      required String nome,
      required String email,
      required String senha,
      required DateTime dataNascimento,
      required String telefone,
      required String fotoPath,
      required int ativo,
      required Genero genero})
      : super(
            id: id,
            tipo: tipo,
            nome: nome,
            email: email,
            senha: senha,
            dataNascimento: dataNascimento,
            telefone: telefone,
            fotoPath: fotoPath,
            ativo: ativo,
            genero: genero);

  Map<String, dynamic> toJson() => {
        ...{'altura': this.altura, 'peso': this.peso, 'cpf': this.cpf},
        ...retornaBaseMap()
      };
}