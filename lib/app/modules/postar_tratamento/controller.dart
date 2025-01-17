import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:healthbox/app/data/enums/tipo_notificacao.dart';
import 'package:healthbox/app/data/enums/tipo_usuario.dart';
import 'package:healthbox/app/data/models/acompanhamento.dart';
import 'package:healthbox/app/data/models/medicamento.dart';
import 'package:healthbox/app/data/models/medicamento_info.dart';
import 'package:healthbox/app/data/models/notificacao.dart';
import 'package:healthbox/app/data/models/opiniao.dart';
import 'package:healthbox/app/data/models/questao.dart';
import 'package:healthbox/app/data/models/questionario.dart';
import 'package:healthbox/app/data/models/tratamento.dart';
import 'package:healthbox/app/data/models/vinculo.dart';
import 'package:healthbox/app/data/providers/conta.dart';
import 'package:healthbox/app/data/repositories/conta.dart';
import 'package:healthbox/app/data/repositories/tratamento.dart';
import 'package:healthbox/app/modules/acompanhamentos/controller.dart';
import 'package:healthbox/app/modules/opinioes/controller.dart';
import 'package:healthbox/core/theme/easy_loading_config.dart';
import 'package:healthbox/routes/app_pages.dart';
import 'package:intl/intl.dart';

import '../login/controller.dart';

class PostarTratamentoController extends GetxController {
  final TratamentoRepository repository;
  dynamic usuario;
  final loginController = Get.find<LoginController>();
  PostarTratamentoController({required this.repository})
      : assert(repository != null) {
    usuario = loginController.getLogin();
    isPaciente = usuario.tipo == TipoUsuario.PACIENTE;
    if (!isPaciente) {
      getVinculos();
      getQuestoesPreCadastradas();
    } else {
      getMeusAcompanhamentos();
    }
    doc = Document()..insert(0, ' ');
  }

  @override
  void onInit() {
    super.onInit();
  }

  //======================TODOS==========================================
  final _activeStepIndex = 0.obs;
  final _isPaciente = false.obs;
  final tituloController = TextEditingController();
  final descricaoController = TextEditingController();
  final _rollBack = false.obs;
  get rollBack => this._rollBack.value;
  set rollBack(value) => this._rollBack.value = value;
  get isPaciente => this._isPaciente.value;
  set isPaciente(value) => this._isPaciente.value = value;
  get activeStepIndex => this._activeStepIndex.value;
  setActiveStepIndex(value) => this._activeStepIndex.value =
      isValidStep(activeStepIndex) || value < activeStepIndex
          ? value
          : activeStepIndex;
  activeStepIndexIncrease() => this._activeStepIndex.value++;
  activeStepIndexDecrease() => this._activeStepIndex.value--;

  bool isValidStep(int step) {
    bool retorno = false;
    if (isPaciente) {
      switch (step) {
        case 0:
          retorno = true;
          break;
        case 1:
          retorno = step1Valido();
          break;
        case 2:
          retorno = step3PacienteValido();
          break;
      }
    } else {
      switch (step) {
        case 0:
          retorno = step0Valido();
          break;
        case 1:
          retorno = step1Valido();
          break;
        case 2:
          retorno = step2Valido();
          break;
        case 3:
          retorno = step3MedicoValido();
          break;
        case 4:
          retorno = step4MedicoValido();
          break;
        default:
          retorno = step4MedicoValido();
      }
    }

    return retorno;
  }

  StepState getStepState(int step) {
    if (step == activeStepIndex) return StepState.editing;
    if (step != activeStepIndex && isValidStep(step)) return StepState.complete;
    if (step != activeStepIndex && !isValidStep(step)) return StepState.indexed;
    return StepState.indexed;
  }

  bool checkDataInicial() {
    DateTime hoje = DateTime.now().toLocal();
    hoje = DateTime(hoje.year, hoje.month, hoje.day);
    return dataInicial != null &&
        dataInicial.difference(hoje).inDays <= 0 &&
        idPostagem != null;
  }

  //===============Focus===================
  FocusNode tituloTratamentoFocus = FocusNode();
  FocusNode descricaoTratamentoFocus = FocusNode();
  FocusNode tituloQuestionarioFocus = FocusNode();
  FocusNode descricaoQuestionarioFocus = FocusNode();
  FocusNode duracaoFocus = FocusNode();
  FocusNode intervaloFocus = FocusNode();

  //===============================STEP 0================================
  final vinculos = <Vinculo>[].obs;
  final _vinculo = Rx<Vinculo?>(null);
  final _isVinculoUntouched = true.obs;
  final _carregandoVinculos = false.obs;

  get carregandoVinculos => this._carregandoVinculos.value;
  set carregandoVinculos(value) => this._carregandoVinculos.value = value;

  get vinculo => this._vinculo.value;
  set vinculo(value) => this._vinculo.value = value;

  get isVinculoUntouched => this._isVinculoUntouched.value;
  setIsVinculoUntouched() => this._isVinculoUntouched.value = false;
  step0Valido() => vinculoValido();
  bool vinculoValido() => vinculo != null;

  String? get vinculoErroMensagem {
    if (isVinculoUntouched || vinculoValido()) return null;
    return 'Campo de paciente é obrigátorio';
  }

  getVinculos() {
    carregandoVinculos = true;
    ContaRepository(provider: ContaProvider()).getVinculos(1).then((retorno) {
      vinculos.clear();
      vinculos.assignAll(retorno);
      carregandoVinculos = false;
    });
  }

//===============================STEP 1==================================
  final _doc = Rx<Document>(Document()..insert(0, ' '));
  final _texto = Rx<String?>(null);
  final _titulo = Rx<String?>(null);
  final _idPostagem = Rx<int?>(null);
  final _idTratamento = Rx<int?>(null);
  final _idQuestionario = Rx<int?>(null);
  final _carregando = false.obs;
  final _eficacia = 1.obs;
  QuillController controller_editor = QuillController.basic();

  get idPostagem => this._idPostagem.value;
  set idPostagem(value) => this._idPostagem.value = value;
  get idTratamento => this._idTratamento.value;
  set idTratamento(value) => this._idTratamento.value = value;
  get idQuestionario => this._idQuestionario.value;
  set idQuestionario(value) => this._idQuestionario.value = value;
  get doc => this._doc.value;
  set doc(value) => this._doc.value = value;
  get titulo => this._titulo.value;
  setTitulo(value) => this._titulo.value = value;
  get texto => this._texto.value;
  set texto(value) => this._texto.value = value;
  get carregando => this._carregando.value;
  set carregando(value) => this._carregando.value = value;
  get eficacia => this._eficacia.value;
  setEficacia(value) => this._eficacia.value = value;
  get editorLength => controller_editor.document.toPlainText().length;

  bool step1Valido() => textoValido() && tituloValido();

  bool tituloValido() => titulo != null && titulo.isNotEmpty;

  String? get tituloErroMensagem {
    if (titulo == null || tituloValido()) return null;
    return 'Campo obrigatório';
  }

  bool textoValido() =>
      texto != null && editorLength > 10 && editorLength <= 200;

  String? get textoErroMensagem {
    if (texto == null || textoValido()) return null;
    if (editorLength > 200) return 'Descrição muito longa';
    return 'Descrição muito curta';
  }
  //===============================STEP 2==================================

  final medicamentosSelecionadosInfo = <MedicamentoInfo>[].obs;
  Future<List<Medicamento>> getMedicamentos(String? filtro) async {
    if (filtro == null) return List<Medicamento>.empty();
    return await repository.getMedicamentosFiltro(filtro);
  }

  final _descricao = ''.obs;
  get descricao => this._descricao.value;
  setDescricao(value) => this._descricao.value = value;

  bool medicamentosSelecionadosValid() =>
      medicamentosSelecionadosInfo.where((item) => item.dose.isEmpty).length <=
      0;

  bool step2Valido() => medicamentosSelecionadosValid();

  //==================STEP 3 Paciente========================================

  bool step3PacienteValido() => step1Valido() && step2Valido();

  //==================STEP 3 Medico========================================

  bool step3MedicoValido() => questoesValida() && tituloQuestionarioValido();
  List<Questao> questoes = <Questao>[].obs;
  List<Questao> questoesPreCadastradas = <Questao>[].obs;
  final _isQuestoesUntouched = true.obs;
  final _carregandoQuestoes = false.obs;
  get carregandoQuestoes => this._carregandoQuestoes.value;
  set carregandoQuestoes(value) => this._carregandoQuestoes.value = value;
  get isQuestoesUntouched => this._isQuestoesUntouched.value;
  setIsQuestoesUntouched(value) => this._isQuestoesUntouched.value = value;

  addQuestao(Questao questao, bool tipo) async {
    if (tipo) {
      carregandoQuestoes = true;
      repository.salvarQuestao(questao).then((retorno) {
        if (retorno == null || retorno is bool) {
          EasyLoading.showToast('Erro ao adicionar questão',
              duration: const Duration(milliseconds: 500),
              toastPosition: EasyLoadingToastPosition.bottom);
        } else {
          if (questao.id == null) {
            questao.id = retorno;
            questoes.add(questao);
          } else {
            int indexQuestao =
                questoes.indexWhere((element) => element.id == questao.id);
            questoes[indexQuestao] = questao;
          }

          EasyLoading.showToast('Questão adicionada com sucesso',
              duration: const Duration(milliseconds: 500),
              toastPosition: EasyLoadingToastPosition.bottom);
        }
        questoesPreCadastradas
            .removeWhere((element) => element.id == questao.id);
        carregandoQuestoes = false;
      });
      return;
    }
    questoesPreCadastradas.removeWhere((element) => element.id == questao.id);
    questoes.add(questao);
  }

  deletarQuestao(int index) {
    carregandoQuestoes = true;
    int id = questoes[index].id!;
    repository.deletarQuestao(id).then((retorno) {
      if (retorno) {
        questoes.removeAt(index);
        getQuestoesPreCadastradas();
        EasyLoading.showToast('Questão deletada com sucesso',
            duration: const Duration(milliseconds: 500),
            toastPosition: EasyLoadingToastPosition.bottom);
      } else {
        EasyLoading.showToast('Erro ao deletar questão',
            duration: const Duration(milliseconds: 500),
            toastPosition: EasyLoadingToastPosition.bottom);
      }
      carregandoQuestoes = false;
    });
  }

  removerQuestao(int index) {
    Get.back();
    questoesPreCadastradas.add(questoes[index]);
    questoes.removeAt(index);
  }

  final _tituloQuestionario = Rx<String?>(null);

  final _descricaoQuestionario = ''.obs;
  get tituloQuestionario => this._tituloQuestionario.value;
  setTituloQuestionario(value) => this._tituloQuestionario.value = value;
  get descricaoQuestionario => this._descricaoQuestionario.value;
  setDescricaoQuestionario(value) => this._descricaoQuestionario.value = value;

  bool tituloQuestionarioValido() =>
      tituloQuestionario != null && tituloQuestionario.isNotEmpty;

  String? get tituloQuestionarioErroMensagem {
    if (tituloQuestionario == null || tituloQuestionarioValido()) return null;
    return 'Campo obrigatório';
  }

  bool questoesValida() => questoes.isNotEmpty;

  String? get questoesErroMensagem {
    if (isQuestoesUntouched || questoesValida()) return null;
    return 'Nenhuma questão adicionada ao questionário';
  }

  getQuestoesPreCadastradas() {
    carregandoQuestoes = true;
    repository.getQuestoesPreCadastradas().then((retorno) {
      questoesPreCadastradas.clear();
      var lista = retorno.where(
          (element) => !questoes.any((element1) => element1.id == element.id));
      questoesPreCadastradas.assignAll(lista);
      carregandoQuestoes = false;
    });
  }

  //==================STEP 4========================================

  final _dataInicial = Rx<DateTime?>(null);

  final _quantidadePeriodicidade = Rx<int?>(null);
  final _diasDuracao = Rx<int?>(null);

  final _isDataInicialUntouched = true.obs;

  String get formataDataInicial => dataInicial == null
      ? 'Nenhuma data selecionada'
      : DateFormat('dd/MM/yyyy').format(dataInicial);

  get dataInicial => this._dataInicial.value;
  set dataInicial(value) {
    this._dataInicial.value = value;
    isDataInicialUntouched = false;
  }

  get quantidadePeriodicidade => this._quantidadePeriodicidade.value;
  setQuantidadePeriodicidade(value) => this._quantidadePeriodicidade.value =
      value == null || value.isEmpty ? 0 : int.parse(value);

  get diasDuracao => this._diasDuracao.value;
  setDiasDuracao(value) => this._diasDuracao.value =
      value == null || value.isEmpty ? 0 : int.parse(value);

  get isDataInicialUntouched => this._isDataInicialUntouched.value;
  set isDataInicialUntouched(value) =>
      this._isDataInicialUntouched.value = false;

  bool dataInicialValida() => dataInicial != null;

  String? get dataInicialErroMensagem {
    if (isDataInicialUntouched || dataInicialValida()) return null;
    return 'Campo de data inicial é obrigátorio';
  }

  bool diasQuestionarioValida() => diasDuracao != null && diasDuracao != 0;

  bool periodicidadeQuestionarioValida() =>
      quantidadePeriodicidade != null && quantidadePeriodicidade != 0;

  String? get duracaoQuestionarioErroMensagem {
    if ((diasDuracao == null && quantidadePeriodicidade == null) ||
        (diasQuestionarioValida() && periodicidadeQuestionarioValida()))
      return null;
    // if (diasQuestionarioValida() && periodicidadeQuestionarioValida()) {
    //   return diasDuracao > quantidadePeriodicidade
    //       ? null
    //       : 'Duração precisa ser maior do que o intervalo';
    // }

    String retorno = 'Campo(s) obrigatórios';
    if (!diasQuestionarioValida()) retorno += '(duração em dias)';
    if (!periodicidadeQuestionarioValida()) {
      retorno += ' (intervalo entre questionários)';
    }

    return retorno;
  }

  DateTime getDataInicialDisponivel() => idPostagem == null
      ? DateTime.now()
      : DateTime.now().add(const Duration(days: 1));

  bool step4MedicoValido() =>
      dataInicialValida() &&
      diasQuestionarioValida() &&
      periodicidadeQuestionarioValida();

  // =====================================================================================

  //===========================================Acompanhamentos=============================================

  final meusAcompanhamentos = <Acompanhamento>[].obs;
  final _carregandoMeusAcompanhamentos = false.obs;
  final _acompanhamento = Rx<Acompanhamento?>(null);

  get carregandoMeusAcompanhamento => this._carregandoMeusAcompanhamentos.value;
  set carregandoMeusAcompanhamento(value) =>
      this._carregandoMeusAcompanhamentos.value = value;

  get acompanhamento => this._acompanhamento.value;
  set acompanhamento(value) => this._acompanhamento.value = value;

  erroAcompanhamento() async {
    EasyLoading.instance.backgroundColor = Colors.red;
    await EasyLoading.showError('Erro ao salvar acompanhamento',
        duration: const Duration(milliseconds: 1000));
    EasyLoading.dismiss();
    EasyLoadingConfig();
  }

  sucessoAcompanhamento() {
    EasyLoading.showSuccess('Acompanhamento salvo com sucesso');
    EasyLoading.dismiss();
    EasyLoadingConfig();
    redirectListagemAcompanhamentos();
    Notificacao notificacao = Notificacao(
        titulo: '',
        descricao: '',
        tipo: TipoNotificacao.ACOMPANHAMENTO,
        idDestinario: vinculo.usuarioId,
        fcmToken: vinculo.paciente?.fcmToken ?? '');
    if (idPostagem == null) {
      notificacao.titulo = 'Você tem um novo acompanhamento';
      notificacao.descricao =
          "O seu médico ${usuario.nome} criou um novo acompanhamento para você, chamado '$titulo'";
    } else {
      notificacao.titulo =
          'Um dos seus acompanhamentos recebeu uma atualização';
      notificacao.descricao =
          'O seu médico ${usuario.nome} atualizou o seu acompanhamento $titulo';
    }
    notificacao.medico = usuario;
    loginController.enviarNotificacao(notificacao);
  }

  setmeuAcompanhamento(Acompanhamento? acompanhamentoParam) {
    acompanhamento = acompanhamentoParam;
    if (acompanhamento == null) {
      setTitulo(null);
      tituloController.clear();
      descricaoController.clear();

      setDescricao(null);
      medicamentosSelecionadosInfo.clear();
    } else {
      setTitulo(acompanhamento.tratamento.titulo);
      tituloController.text = titulo;
      var textoTemp = acompanhamento.tratamento!.descricao;
      var docTemp = Document.fromJson(jsonDecode(textoTemp));
      setDescricao(docTemp.toPlainText());
      descricaoController.text = descricao;
      medicamentosSelecionadosInfo.assignAll(
          acompanhamentoParam?.tratamento?.medicamentos ??
              List<MedicamentoInfo>.empty());
    }
  }

  salvarAcompanhamento() {
    EasyLoading.showInfo('Salvando...', duration: const Duration(days: 1));

    texto = jsonEncode(controller_editor.document.toDelta().toJson());
    Acompanhamento acompanhamento = Acompanhamento(
        descricaoPaciente: descricao,
        pacienteId: vinculo.usuarioId,
        medicoId: usuario.id,
        ativo: 1,
        dataInicio: dataInicial,
        quantidadePeriodicidade: quantidadePeriodicidade,
        diasDuracao: diasDuracao);

    if (idPostagem != null) acompanhamento.id = idPostagem;
    repository
        .salvarAcompanhamento(acompanhamento)
        .then((retornoAcompanhamento) {
      if (retornoAcompanhamento == null || retornoAcompanhamento is bool) {
        erroAcompanhamento();
      } else {
        Tratamento tratamento = Tratamento(
            titulo: titulo,
            descricao: texto,
            acompanhamentoId: retornoAcompanhamento,
            medicamentos: medicamentosSelecionadosInfo);
        if (idTratamento != null) tratamento.id = idTratamento;

        repository.salvarTratamento(tratamento).then((retornoTratamento) {
          if (retornoTratamento) {
            if (checkDataInicial()) {
              sucessoAcompanhamento();
              return;
            }
            Questionario questionario = Questionario(
                titulo: tituloQuestionario,
                descricao: descricaoQuestionario,
                acompanhamentoId: retornoAcompanhamento);
            if (idQuestionario != null) questionario.id = idQuestionario;
            repository
                .salvarQuestionario(questionario)
                .then((retornoQuestionario) {
              if (retornoQuestionario == null || retornoQuestionario is bool) {
                rollBackAcompanhamento(retornoAcompanhamento);
                erroAcompanhamento();
              } else {
                Map<String, List<Map<String, dynamic>>> vinculos = {
                  'vinculos': []
                };

                questoes.forEach((questao) => vinculos['vinculos']!.add({
                      'questionario_id': retornoQuestionario,
                      'questao_id': questao.id
                    }));

                repository
                    .salvarIntermediaria(vinculos)
                    .then((retornoIntermediaria) {
                  if (retornoIntermediaria) {
                    sucessoAcompanhamento();
                  } else {
                    rollBackAcompanhamento(retornoAcompanhamento);
                    erroAcompanhamento();
                  }
                });
              }
            });
          } else {
            rollBackAcompanhamento(retornoAcompanhamento);
            erroAcompanhamento();
          }
        });
      }
      EasyLoading.dismiss();
    });
  }

  rollBackAcompanhamento(int id) {
    if (idPostagem == null) {
      rollBack = true;
      idPostagem = id;
      deletarAcompanhamento();
    }
  }

  deletarAcompanhamento() {
    repository.deletarAcompanhamento(idPostagem).then((retorno) {
      idPostagem = null;
      if (retorno) {
        if (!rollBack) {
          EasyLoading.showToast('Acompanhamento deletado com sucesso',
              toastPosition: EasyLoadingToastPosition.bottom);
          redirectListagemAcompanhamentos();
        }
      } else {
        if (!rollBack) {
          EasyLoading.showToast('Erro ao deletar  Acompanhamento',
              toastPosition: EasyLoadingToastPosition.bottom);
        }
      }
      rollBack = false;
    });
  }

  getMeusAcompanhamentos() {
    carregandoMeusAcompanhamento = true;
    repository.getAcompanhamentos().then((retorno) {
      meusAcompanhamentos.assignAll(retorno);
      carregandoMeusAcompanhamento = false;
    });
  }

  redirectListagemAcompanhamentos() {
    final acompanhamentoController = Get.find<AcompanhamentosController>();
    //int index = acompanhamentoController.getIndexUsuarioSelecionado();
    if (acompanhamentoController.tipoVisualizacao == 1) {
      acompanhamentoController.getUsuariosAcompanhamentos();
    } else {
      acompanhamentoController.getQuestionarios();
    }

    Get.offNamed(Routes.ACOMPANHAMENTOS);
  }

  //===========================================OPINIÕES=============================================
  setEdicaoOpiniao(Opiniao opiniao) {
    if (opiniao.pacienteId != usuario.id) {
      Get.offNamed(Routes.INITIAL);
      return;
    }

    idTratamento = opiniao.tratamento!.id;
    idPostagem = opiniao.id;
    texto = opiniao.descricao;
    doc = Document.fromJson(jsonDecode(texto));
    setTitulo(opiniao.tratamento?.titulo ?? '');
    tituloController.text = titulo;
    medicamentosSelecionadosInfo.clear();
    medicamentosSelecionadosInfo.assignAll(
        opiniao.tratamento?.medicamentos ?? List<MedicamentoInfo>.empty());
    setEficacia(opiniao.eficaz);
    setDescricao(opiniao.tratamento?.descricao ?? '');
    descricaoController.text = descricao;
  }

  setEdicaoAcompanhamento(Acompanhamento acompanhamento) {
    if (acompanhamento.medicoId != usuario.id) {
      Get.offNamed(Routes.ACOMPANHAMENTOS);
      return;
    }

    idTratamento = acompanhamento.tratamento!.id;
    idPostagem = acompanhamento.id;
    idQuestionario = acompanhamento.questionario?.id;
    texto = acompanhamento.tratamento!.descricao;
    doc = Document.fromJson(jsonDecode(texto));
    setTitulo(acompanhamento.tratamento?.titulo ?? '');
    tituloController.text = titulo;
    setTituloQuestionario(acompanhamento.questionario?.titulo ?? '');
    setDescricaoQuestionario(acompanhamento.questionario?.descricao ?? '');
    dataInicial = acompanhamento.dataInicio;
    medicamentosSelecionadosInfo.assignAll(
        acompanhamento.tratamento?.medicamentos ??
            List<MedicamentoInfo>.empty());
    questoes.assignAll(
        acompanhamento.questionario?.questoes ?? List<Questao>.empty());
    setDescricao(acompanhamento.descricaoPaciente);

    setDiasDuracao('${acompanhamento.diasDuracao}');
    setQuantidadePeriodicidade('${acompanhamento.quantidadePeriodicidade}');

    vinculo = Vinculo(
        usuarioId: acompanhamento.paciente!.id!,
        nome: acompanhamento.paciente!.nome,
        fotoPath: acompanhamento.paciente!.fotoPath,
        paciente: acompanhamento.paciente);
    // await Future.delayed(const Duration(seconds: 5));
    // _vinculo.update((val) {
    //   vinculo = Vinculo(
    //       usuarioId: acompanhamento.paciente!.id!,
    //       nome: acompanhamento.paciente!.nome,
    //       fotoPath: acompanhamento.paciente!.fotoPath,
    //       paciente: acompanhamento.paciente);
    // });
  }

  salvarOpiniao() {
    EasyLoading.showInfo('Salvando...', duration: const Duration(days: 1));

    texto = jsonEncode(controller_editor.document.toDelta().toJson());

    Opiniao opiniao = Opiniao(
        descricao: texto, pacienteId: usuario.id, eficaz: eficacia, ativo: 1);
    if (idPostagem != null) opiniao.id = idPostagem;
    repository.salvarOpiniao(opiniao).then((retorno) {
      if (retorno == null || retorno is bool) {
        EasyLoading.instance.backgroundColor = Colors.red;
        EasyLoading.showError('Erro ao salvar opinião');
        EasyLoadingConfig();
      } else {
        Tratamento tratamento = Tratamento(
            titulo: titulo,
            descricao: descricao,
            opiniaoId: retorno,
            medicamentos: medicamentosSelecionadosInfo);
        if (idTratamento != null) tratamento.id = idTratamento;

        repository.salvarTratamento(tratamento).then((retorno1) {
          if (retorno1) {
            EasyLoading.showSuccess('Opinião salva com sucesso');
            EasyLoadingConfig();
            redirectListagemOpinioes();
          } else {
            if (idPostagem == null) {
              rollBack = true;
              idPostagem = retorno;
              deletarOpiniao();
            }
            EasyLoading.instance.backgroundColor = Colors.red;
            EasyLoading.showError('Erro ao salvar opinião');
            EasyLoadingConfig();
          }
          EasyLoading.dismiss();
        });
      }
      EasyLoading.dismiss();
    });
  }

  deletarOpiniao() {
    repository.deletarOpiniao(idPostagem).then((retorno) {
      idPostagem = null;
      if (retorno) {
        if (!rollBack) {
          EasyLoading.showToast('Opinião deletada com sucesso',
              toastPosition: EasyLoadingToastPosition.bottom);
          redirectListagemOpinioes();
        }
      } else {
        if (!rollBack) {
          EasyLoading.showToast('Erro ao deletar  Opinião',
              toastPosition: EasyLoadingToastPosition.bottom);
        }
      }
      rollBack = false;
    });
  }

  redirectListagemOpinioes() {
    Get.find<OpinioesController>().getOpinioes();
    Get.offNamed(Routes.INITIAL);
  }
}
