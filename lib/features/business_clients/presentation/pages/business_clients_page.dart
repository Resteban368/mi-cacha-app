import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../business_reservations/domain/entities/customer.dart';
import '../../domain/entities/client_profile.dart';
import '../bloc/business_clients_bloc.dart';
import '../bloc/business_clients_event.dart';
import '../bloc/business_clients_state.dart';
import '../widgets/client_card_item.dart';
import '../widgets/client_detail_sheet.dart';
import '../widgets/client_form_dialog.dart';
import '../widgets/clients_data_table.dart';
import '../widgets/clients_filter_bar.dart';
import '../widgets/clients_metric_cards.dart';

/// Pantalla principal optimizada para Web y Móvil: Directorio y CRM de Clientes del negocio.
class BusinessClientsPage extends StatefulWidget {
  const BusinessClientsPage({super.key, this.initialClients});

  final List<ClientProfile>? initialClients;

  @override
  State<BusinessClientsPage> createState() => _BusinessClientsPageState();
}

class _BusinessClientsPageState extends State<BusinessClientsPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onWhatsApp(ClientProfile client) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Iniciando chat con ${client.name} (${client.phone})'),
        backgroundColor: AppColors.brandTeal,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onNewReservation(ClientProfile client) {
    context.go(
      AppRoutes.businessNewReservation,
      extra: Customer(
        id: client.id,
        name: client.name,
        phone: client.phone,
        documentId: client.documentId,
      ),
    );
  }

  void _onOpenHistory(ClientProfile client) {
    context.go(AppRoutes.businessCustomerReservations(client.id, client.name));
  }

  Future<void> _openNewClientDialog() async {
    final newClient = await showClientFormDialog(context);
    if (newClient != null && mounted) {
      context.read<BusinessClientsBloc>().add(const BusinessClientsRefreshed());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cliente "${newClient.name}" registrado con éxito'),
          backgroundColor: AppColors.brandTeal,
        ),
      );
    }
  }

  Future<void> _openEditClientDialog(ClientProfile client) async {
    final updated = await showClientFormDialog(context, initialClient: client);
    if (updated != null && mounted) {
      context.read<BusinessClientsBloc>().add(const BusinessClientsRefreshed());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ficha de "${updated.name}" actualizada'),
          backgroundColor: AppColors.brandTeal,
        ),
      );
    }
  }

  void _openDetail(ClientProfile client) {
    showClientDetailSheet(
      context,
      client: client,
      onNewReservation: () => _onNewReservation(client),
      onOpenHistory: () => _onOpenHistory(client),
      onWhatsApp: () => _onWhatsApp(client),
      onEdit: () => _openEditClientDialog(client),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<BusinessClientsBloc>();

    return Column(
      children: [
        const AppTopBar(
          title: 'Clientes',
          subtitle: 'Directorio de jugadores, fidelidad y contacto directo',
          icon: Icons.group_rounded,
        ),
        Expanded(
          child: BlocConsumer<BusinessClientsBloc, BusinessClientsState>(
            listener: (context, state) {
              if (state.errorMessage != null &&
                  state.status == ClientsStatus.failure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage!),
                    backgroundColor: AppColors.statusDue,
                  ),
                );
              }
            },
            builder: (context, state) {
              final clients = widget.initialClients ?? state.clients;
              final isLoading = state.status == ClientsStatus.loading;
              final isFailure = state.status == ClientsStatus.failure && clients.isEmpty;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final isDesktop = width >= 840;
                  final gutter = isDesktop ? 24.0 : 16.0;

                  return RefreshIndicator(
                    onRefresh: () async {
                      bloc.add(const BusinessClientsRefreshed());
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 32),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1440),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // KPI Metric Cards Row
                              ClientsMetricCards(
                                overview: state.overview,
                                clients: clients,
                              ),
                              const SizedBox(height: 20),

                              // Search and Filter Bar
                              ClientsFilterBar(
                                searchController: _searchController,
                                selectedFilter: state.query.segment,
                                selectedSort: state.query.sort,
                                totalClients: state.totalClients,
                                filteredClients: clients.length,
                                onSearchChanged: (query) {
                                  bloc.add(BusinessClientsSearchChanged(query));
                                },
                                onFilterChanged: (filter) {
                                  bloc.add(BusinessClientsSegmentChanged(filter));
                                },
                                onSortChanged: (sort) {
                                  bloc.add(BusinessClientsSortChanged(sort));
                                },
                                onNewClientPressed: _openNewClientDialog,
                              ),
                              const SizedBox(height: 20),

                              if (isFailure)
                                _buildErrorState(state.errorMessage, () {
                                  bloc.add(const BusinessClientsRefreshed());
                                })
                              else if (isLoading && clients.isEmpty)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(48.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else ...[
                                if (isLoading)
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 12),
                                    child: LinearProgressIndicator(
                                      color: AppColors.brandTeal,
                                      backgroundColor: AppColors.brandTealLight,
                                    ),
                                  ),

                                // Data Table for Web / Desktop OR Cards for Mobile
                                if (isDesktop)
                                  ClientsDataTable(
                                    clients: clients,
                                    onClientTap: _openDetail,
                                    onWhatsAppTap: _onWhatsApp,
                                    onNewReservationTap: _onNewReservation,
                                    onHistoryTap: _onOpenHistory,
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: clients.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, i) {
                                      final client = clients[i];
                                      return ClientCardItem(
                                        client: client,
                                        onTap: () => _openDetail(client),
                                        onWhatsAppTap: () => _onWhatsApp(client),
                                        onNewReservationTap: () =>
                                            _onNewReservation(client),
                                        onHistoryTap: () => _onOpenHistory(client),
                                      );
                                    },
                                  ),

                                // Pagination Footer
                                if (state.totalPages > 1) ...[
                                  const SizedBox(height: 16),
                                  _buildPaginationBar(state, bloc),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String? message, VoidCallback onRetry) {
    return Container(
      padding: const EdgeInsets.all(48),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 28,
              color: AppColors.statusDue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar clientes',
            style: AppTypography.headlineSm.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message ?? 'No se pudo comunicar con el servidor.',
            style: AppTypography.bodyMd.copyWith(color: AppColors.slate500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reintentar'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandTeal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationBar(
    BusinessClientsState state,
    BusinessClientsBloc bloc,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            onPressed: state.hasPreviousPage
                ? () => bloc.add(BusinessClientsPageChanged(state.currentPage - 1))
                : null,
            icon: const Icon(Icons.chevron_left_rounded, size: 18),
            label: const Text('Anterior'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Text(
            'Página ${state.currentPage} de ${state.totalPages}',
            style: AppTypography.labelMd.copyWith(
              color: AppColors.slate700,
              fontWeight: FontWeight.w600,
            ),
          ),
          OutlinedButton.icon(
            onPressed: state.hasNextPage
                ? () => bloc.add(BusinessClientsPageChanged(state.currentPage + 1))
                : null,
            icon: const Icon(Icons.chevron_right_rounded, size: 18),
            label: const Text('Siguiente'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
