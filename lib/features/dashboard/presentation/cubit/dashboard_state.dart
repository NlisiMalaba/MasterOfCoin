part of 'dashboard_cubit.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  const DashboardLoaded({
    required this.usdBalance,
    required this.zwgBalance,
    required this.usdIncome,
    required this.usdExpenses,
    required this.zwgIncome,
    required this.zwgExpenses,
  });

  final double usdBalance;
  final double zwgBalance;
  final double usdIncome;
  final double usdExpenses;
  final double zwgIncome;
  final double zwgExpenses;

  @override
  List<Object?> get props =>
      [usdBalance, zwgBalance, usdIncome, usdExpenses, zwgIncome, zwgExpenses];
}

class DashboardError extends DashboardState {
  const DashboardError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
