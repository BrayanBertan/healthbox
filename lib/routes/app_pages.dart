import 'package:get/get.dart';

import '../app/modules/conta/binding.dart';
import '../app/modules/conta/dados_usuario/binding.dart';
import '../app/modules/conta/dados_usuario/view.dart';
import '../app/modules/conta/view.dart';
import '../app/modules/graficos_opinioes/binding.dart';
import '../app/modules/graficos_opinioes/view.dart';
import '../app/modules/login/view.dart';
import '../app/modules/opinioes/binding.dart';
import '../app/modules/opinioes/view.dart';
import '../app/modules/opinioes/widgets/detalhes_opiniao/page_detalhes_opiniao.dart';
import '../app/modules/postar_tratamento/binding.dart';
import '../app/modules/postar_tratamento/view.dart';
import 'middlewares/autentica_usuario.dart';

part 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(
        name: Routes.INITIAL,
        page: () => OpinioesPage(),
        binding: OpinioesBinding(),
        middlewares: [AutenticaUsuario()]),
    GetPage(
      name: Routes.DETALHES_OPINIAO,
      page: () => PageDetalhesOpiniao(),
    ),
    GetPage(
        name: Routes.POSTAR_TRATAMENTO,
        page: () => PagePostarTratamento(),
        binding: PostarTratamentoBinding()),
    GetPage(
      name: Routes.LOGIN,
      page: () => LoginPage(), /* middlewares: [SetTokenUsuario()]*/
    ),
    GetPage(
        name: Routes.CONTA,
        page: () => ContaPage(),
        bindings: [ContaBinding()],
        middlewares: [AutenticaUsuario()]),
    GetPage(
        name: Routes.DADOS_USUARIO,
        page: () => DadosUsuarioPage(),
        binding: DadosUsuarioBinding()),
    GetPage(
      name: Routes.GRAFICOS_OPINIOES,
      page: () => GraficosOpinioesView(),
      binding: GraficosOpinioesBinding(),
    ),
  ];
}
