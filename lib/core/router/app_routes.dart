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

  static const String stayManagementName = 'stayManagement';
  static const String stayManagementPath = '/stays';
  static const String addStayName = 'addStay';
  static const String addStayPath = 'add';
  static const String stayDetailsName = 'stayDetails';
  static const String stayDetailsPath = ':stayId';
  static const String editStayName = 'editStay';
  static const String editStayPath = ':stayId/edit';

  static const String rentRecordManagementName = 'rentRecordManagement';
  static const String rentRecordManagementPath = '/rent-records';
  static const String addRentRecordName = 'addRentRecord';
  static const String addRentRecordPath = 'add';
  static const String rentRecordDetailsName = 'rentRecordDetails';
  static const String rentRecordDetailsPath = ':rentRecordId';
  static const String editRentRecordName = 'editRentRecord';
  static const String editRentRecordPath = ':rentRecordId/edit';

  static const String paymentManagementName = 'paymentManagement';
  static const String paymentManagementPath = '/payments';
  static const String addPaymentName = 'addPayment';
  static const String addPaymentPath = 'add';
  static const String paymentDetailsName = 'paymentDetails';
  static const String paymentDetailsPath = ':paymentId';
  static const String editPaymentName = 'editPayment';
  static const String editPaymentPath = ':paymentId/edit';

  static const String receiptManagementName = 'receiptManagement';
  static const String receiptManagementPath = '/receipts';
  static const String addReceiptName = 'addReceipt';
  static const String addReceiptPath = 'add';
  static const String receiptDetailsName = 'receiptDetails';
  static const String receiptDetailsPath = ':receiptId';
  static const String editReceiptName = 'editReceipt';
  static const String editReceiptPath = ':receiptId/edit';
}
