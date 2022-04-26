import 'package:flutter/material.dart';
import 'package:healthbox/app/modules/acompanhamentos/widgets/filtros/card_acompanhamentos.dart';
import 'package:healthbox/app/modules/acompanhamentos/widgets/filtros/card_pesquisa.dart';
import 'package:healthbox/app/widgets/side_menu/side_menu.dart';

class AcompanhamentoPage extends StatelessWidget {
  const AcompanhamentoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acompanhamentos'),
      ),
      drawer: SideMenu(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: const [CardPesquisa(), CardAcompanhamentos()],
        ),
      ),
    );
  }
}