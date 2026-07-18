abstract final class AppRoutes {
  static const String splashName = 'splash';
  static const String splashPath = '/';

  static const String roleSelectionName = 'roleSelection';
  static const String roleSelectionPath = '/role-selection';

  static const String ownerLoginName = 'ownerLogin';
  static const String ownerLoginPath = '/owner/login';

  static const String ownerSignUpName = 'ownerSignUp';
  static const String ownerSignUpPath = '/owner/signup';

  static const String pinSetupName = 'pinSetup';
  static const String pinSetupPath = '/owner/pin-setup';

  static const String managerLoginName = 'managerLogin';
  static const String managerLoginPath = '/manager/login';

  static const String hostelSetupName = 'hostelSetup';
  static const String hostelSetupPath = '/hostel/setup';

  static const String homeName = 'home';
  static const String homePath = '/home';

  static const String roomManagementName = 'roomManagement';
  static const String roomManagementPath = '/rooms';

  static const String addRoomName = 'addRoom';
  static const String addRoomPath = 'add';

  static const String editRoomName = 'editRoom';
  static const String editRoomPath = ':roomId/edit';

  static const String bedManagementName = 'bedManagement';
  static const String bedManagementPath = ':roomId/beds';

  static const String tenantManagementName = 'tenantManagement';
  static const String tenantManagementPath = '/tenants';

  static const String addTenantName = 'addTenant';
  static const String addTenantPath = 'add';

  static const String editTenantName = 'editTenant';
  static const String editTenantPath = ':tenantId/edit';

  static const String transferTenantName = 'transferTenant';
  static const String transferTenantPath = ':tenantId/transfer';
}
