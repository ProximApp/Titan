// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'openapi.swagger.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$Openapi extends Openapi {
  _$Openapi([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = Openapi;

  @override
  Future<Response<List<SpeciesComplete>>> _seedLibrarySpeciesGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Return all species from database as a list of SpeciesComplete schemas',
      summary: 'Get All Species',
      operationId: 'get_all_species_seed_library_species__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["seed_library"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/seed_library/species/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<SpeciesComplete>, SpeciesComplete>($request);
  }

  @override
  Future<Response<SpeciesComplete>> _seedLibrarySpeciesPost({
    required SpeciesBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a new Species by giving an SpeciesBase scheme
**This endpoint is only usable by seed_library **''',
      summary: 'Create Species',
      operationId: 'create_species_seed_library_species__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["seed_library"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/seed_library/species/');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<SpeciesComplete, SpeciesComplete>($request);
  }

  @override
  Future<Response<SpeciesTypesReturn>> _seedLibrarySpeciesTypesGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Return all available types of species from SpeciesType enum.',
      summary: 'Get All Species Types',
      operationId: 'get_all_species_types_seed_library_species_types_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["seed_library"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/seed_library/species/types');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<SpeciesTypesReturn, SpeciesTypesReturn>($request);
  }

  @override
  Future<Response<void>> _seedLibrarySpeciesSpeciesIdPatch({
    required String? speciesId,
    required SpeciesEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Update a Species
**This endpoint is only usable by seed_library**''',
      summary: 'Update Species',
      operationId: 'update_species_seed_library_species__species_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["seed_library"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/seed_library/species/${speciesId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _seedLibrarySpeciesSpeciesIdDelete({
    required String? speciesId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Delete a Species
**This endpoint is only usable by seed_library**''',
      summary: 'Delete Species',
      operationId: 'delete_species_seed_library_species__species_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["seed_library"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/seed_library/species/${speciesId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<PlantSimple>>> _seedLibraryPlantsWaitingGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Return all plants where state=waiting from database as a list of PlantsComplete schemas',
      summary: 'Get Waiting Plants',
      operationId: 'get_waiting_plants_seed_library_plants_waiting_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["seed_library"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/seed_library/plants/waiting');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<PlantSimple>, PlantSimple>($request);
  }

  @override
  Future<Response<List<PlantSimple>>> _seedLibraryPlantsUsersMeGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Return all plants where user ={user_id} from database as a list of PlantsComplete schemas',
      summary: 'Get My Plants',
      operationId: 'get_my_plants_seed_library_plants_users_me_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["seed_library"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/seed_library/plants/users/me');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<PlantSimple>, PlantSimple>($request);
  }

  @override
  Future<Response<List<PlantSimple>>> _seedLibraryPlantsUsersUserIdGet({
    required String? userId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Return all plants where borrower_id = {user_id} from database as a list of PlantsComplete schemas',
      summary: 'Get Plants By User Id',
      operationId:
          'get_plants_by_user_id_seed_library_plants_users__user_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["seed_library"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/seed_library/plants/users/${userId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<PlantSimple>, PlantSimple>($request);
  }

  @override
  Future<Response<PlantComplete>> _seedLibraryPlantsPlantIdGet({
    required String? plantId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Return the plants where plant ={plant_id} from database as a PlantsComplete schemas',
      summary: 'Get Plant By Id',
      operationId: 'get_plant_by_id_seed_library_plants__plant_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["seed_library"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/seed_library/plants/${plantId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<PlantComplete, PlantComplete>($request);
  }

  @override
  Future<Response<void>> _seedLibraryPlantsPlantIdPatch({
    required String? plantId,
    required PlantEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Update a Plant
**This endpoint is only usable by the owner of the plant**''',
      summary: 'Update Plant',
      operationId: 'update_plant_seed_library_plants__plant_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["seed_library"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/seed_library/plants/${plantId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _seedLibraryPlantsPlantIdDelete({
    required String? plantId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Delete a Plant
**This endpoint is only usable by seed_library**''',
      summary: 'Delete Plant',
      operationId: 'delete_plant_seed_library_plants__plant_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["seed_library"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/seed_library/plants/${plantId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<PlantSimple>> _seedLibraryPlantsPost({
    required PlantCreation? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a new Plant by giving an PlantCreation scheme
**This endpoint is only usable if the plant has an ancestor_id or by seed_library **''',
      summary: 'Create Plant',
      operationId: 'create_plant_seed_library_plants__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["seed_library"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/seed_library/plants/');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<PlantSimple, PlantSimple>($request);
  }

  @override
  Future<Response<void>> _seedLibraryPlantsPlantIdAdminPatch({
    required String? plantId,
    required PlantEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Update a Plant
**This endpoint is only usable by seed_library**''',
      summary: 'Update Plant Admin',
      operationId:
          'update_plant_admin_seed_library_plants__plant_id__admin_patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["seed_library"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/seed_library/plants/${plantId}/admin');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _seedLibraryPlantsPlantIdBorrowPatch({
    required String? plantId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Plant borrowed by the user (modify borrowing date, borrower and state)',
      summary: 'Borrow Plant',
      operationId: 'borrow_plant_seed_library_plants__plant_id__borrow_patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["seed_library"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/seed_library/plants/${plantId}/borrow');
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<SeedLibraryInformation>> _seedLibraryInformationGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Seed Library Information',
      operationId: 'get_seed_library_information_seed_library_information_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["seed_library"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/seed_library/information');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<SeedLibraryInformation, SeedLibraryInformation>(
      $request,
    );
  }

  @override
  Future<Response<void>> _seedLibraryInformationPatch({
    required SeedLibraryInformation? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Update Seed Library Information',
      operationId:
          'update_seed_library_information_seed_library_information_patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["seed_library"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/seed_library/information');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<AppModulesAmapSchemasAmapProductComplete>>>
  _amapProductsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Return all products

**The user must be a member of a group authorized to use manage AMAP to use this endpoint**''',
      summary: 'Get Products',
      operationId: 'get_products_amap_products_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["AMAP"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/amap/products');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<
      List<AppModulesAmapSchemasAmapProductComplete>,
      AppModulesAmapSchemasAmapProductComplete
    >($request);
  }

  @override
  Future<Response<AppModulesAmapSchemasAmapProductComplete>> _amapProductsPost({
    required ProductSimple? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a new product

**The user must be a member of a group authorized to use manage AMAP to use this endpoint**''',
      summary: 'Create Product',
      operationId: 'create_product_amap_products_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["AMAP"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/amap/products');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<
      AppModulesAmapSchemasAmapProductComplete,
      AppModulesAmapSchemasAmapProductComplete
    >($request);
  }

  @override
  Future<Response<AppModulesAmapSchemasAmapProductComplete>>
  _amapProductsProductIdGet({
    required String? productId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get a specific product',
      summary: 'Get Product By Id',
      operationId: 'get_product_by_id_amap_products__product_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["AMAP"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/amap/products/${productId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<
      AppModulesAmapSchemasAmapProductComplete,
      AppModulesAmapSchemasAmapProductComplete
    >($request);
  }

  @override
  Future<Response<void>> _amapProductsProductIdPatch({
    required String? productId,
    required AppModulesAmapSchemasAmapProductEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Edit a product

**The user must be a member of a group authorized to use manage AMAP to use this endpoint**''',
      summary: 'Edit Product',
      operationId: 'edit_product_amap_products__product_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["AMAP"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/amap/products/${productId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _amapProductsProductIdDelete({
    required String? productId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Delete a product. A product can not be deleted if it is already used in a delivery.

**The user must be a member of a group authorized to use manage AMAP to use this endpoint**''',
      summary: 'Delete Product',
      operationId: 'delete_product_amap_products__product_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["AMAP"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/amap/products/${productId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<DeliveryReturn>>> _amapDeliveriesGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get all deliveries.',
      summary: 'Get Deliveries',
      operationId: 'get_deliveries_amap_deliveries_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["AMAP"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/amap/deliveries');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<DeliveryReturn>, DeliveryReturn>($request);
  }

  @override
  Future<Response<DeliveryReturn>> _amapDeliveriesPost({
    required DeliveryBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a new delivery.

**The user must be a member of a group authorized to use manage AMAP to use this endpoint**''',
      summary: 'Create Delivery',
      operationId: 'create_delivery_amap_deliveries_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["AMAP"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/amap/deliveries');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<DeliveryReturn, DeliveryReturn>($request);
  }

  @override
  Future<Response<void>> _amapDeliveriesDeliveryIdDelete({
    required String? deliveryId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Delete a delivery.

**The user must be a member of a group authorized to use manage AMAP to use this endpoint**''',
      summary: 'Delete Delivery',
      operationId: 'delete_delivery_amap_deliveries__delivery_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["AMAP"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/amap/deliveries/${deliveryId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _amapDeliveriesDeliveryIdPatch({
    required String? deliveryId,
    required DeliveryUpdate? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Edit a delivery.

**The user must be a member of a group authorized to use manage AMAP to use this endpoint**''',
      summary: 'Edit Delivery',
      operationId: 'edit_delivery_amap_deliveries__delivery_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["AMAP"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/amap/deliveries/${deliveryId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _amapDeliveriesDeliveryIdProductsPost({
    required String? deliveryId,
    required DeliveryProductsUpdate? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Add `product_id` product to `delivery_id` delivery. This endpoint will only add a membership between the two objects.

**The user must be a member of a group authorized to use manage AMAP to use this endpoint**''',
      summary: 'Add Product To Delivery',
      operationId:
          'add_product_to_delivery_amap_deliveries__delivery_id__products_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["AMAP"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/amap/deliveries/${deliveryId}/products');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _amapDeliveriesDeliveryIdProductsDelete({
    required String? deliveryId,
    required DeliveryProductsUpdate? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Remove a given product from a delivery. This won\'t delete the product nor the delivery.

**The user must be a member of a group authorized to use manage AMAP to use this endpoint**''',
      summary: 'Remove Product From Delivery',
      operationId:
          'remove_product_from_delivery_amap_deliveries__delivery_id__products_delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["AMAP"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/amap/deliveries/${deliveryId}/products');
    final $body = body;
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<OrderReturn>>> _amapDeliveriesDeliveryIdOrdersGet({
    required String? deliveryId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get orders from a delivery.

**The user must be a member of a group authorized to use manage AMAP to use this endpoint**''',
      summary: 'Get Orders From Delivery',
      operationId:
          'get_orders_from_delivery_amap_deliveries__delivery_id__orders_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["AMAP"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/amap/deliveries/${deliveryId}/orders');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<OrderReturn>, OrderReturn>($request);
  }

  @override
  Future<Response<OrderReturn>> _amapOrdersOrderIdGet({
    required String? orderId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get content of an order.

**The user must be a member of a group authorized to use manage AMAP to use this endpoint**''',
      summary: 'Get Order By Id',
      operationId: 'get_order_by_id_amap_orders__order_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["AMAP"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/amap/orders/${orderId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<OrderReturn, OrderReturn>($request);
  }

  @override
  Future<Response<void>> _amapOrdersOrderIdPatch({
    required String? orderId,
    required OrderEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Edit an order.

**A member of the group AMAP can edit orders of other users**''',
      summary: 'Edit Order From Delivery',
      operationId: 'edit_order_from_delivery_amap_orders__order_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["AMAP"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/amap/orders/${orderId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _amapOrdersOrderIdDelete({
    required String? orderId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Delete an order.

**A member of the group AMAP can delete orders of other users**''',
      summary: 'Remove Order',
      operationId: 'remove_order_amap_orders__order_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["AMAP"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/amap/orders/${orderId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<OrderReturn>> _amapOrdersPost({
    required OrderBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Add an order to a delivery.

**A member of the group AMAP can create an order for every user**''',
      summary: 'Add Order To Delievery',
      operationId: 'add_order_to_delievery_amap_orders_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["AMAP"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/amap/orders');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<OrderReturn, OrderReturn>($request);
  }

  @override
  Future<Response<void>> _amapDeliveriesDeliveryIdOpenorderingPost({
    required String? deliveryId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Open Ordering Of Delivery',
      operationId:
          'open_ordering_of_delivery_amap_deliveries__delivery_id__openordering_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["AMAP"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/amap/deliveries/${deliveryId}/openordering');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _amapDeliveriesDeliveryIdLockPost({
    required String? deliveryId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Lock Delivery',
      operationId: 'lock_delivery_amap_deliveries__delivery_id__lock_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["AMAP"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/amap/deliveries/${deliveryId}/lock');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _amapDeliveriesDeliveryIdDeliveredPost({
    required String? deliveryId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Mark Delivery As Delivered',
      operationId:
          'mark_delivery_as_delivered_amap_deliveries__delivery_id__delivered_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["AMAP"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/amap/deliveries/${deliveryId}/delivered');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _amapDeliveriesDeliveryIdArchivePost({
    required String? deliveryId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Archive Of Delivery',
      operationId:
          'archive_of_delivery_amap_deliveries__delivery_id__archive_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["AMAP"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/amap/deliveries/${deliveryId}/archive');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<AppModulesAmapSchemasAmapCashComplete>>>
  _amapUsersCashGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get cash from all users.

**The user must be a member of a group authorized to use manage AMAP to use this endpoint**''',
      summary: 'Get Users Cash',
      operationId: 'get_users_cash_amap_users_cash_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["AMAP"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/amap/users/cash');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<
      List<AppModulesAmapSchemasAmapCashComplete>,
      AppModulesAmapSchemasAmapCashComplete
    >($request);
  }

  @override
  Future<Response<AppModulesAmapSchemasAmapCashComplete>>
  _amapUsersUserIdCashGet({
    required String? userId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get cash from a specific user.

**The user must be a member of the group AMAP to use this endpoint or can only access the endpoint for its own user_id**''',
      summary: 'Get Cash By Id',
      operationId: 'get_cash_by_id_amap_users__user_id__cash_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["AMAP"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/amap/users/${userId}/cash');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<
      AppModulesAmapSchemasAmapCashComplete,
      AppModulesAmapSchemasAmapCashComplete
    >($request);
  }

  @override
  Future<Response<AppModulesAmapSchemasAmapCashComplete>>
  _amapUsersUserIdCashPost({
    required String? userId,
    required CashEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create cash for an user.

**The user must be a member of a group authorized to use manage AMAP to use this endpoint**''',
      summary: 'Create Cash Of User',
      operationId: 'create_cash_of_user_amap_users__user_id__cash_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["AMAP"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/amap/users/${userId}/cash');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<
      AppModulesAmapSchemasAmapCashComplete,
      AppModulesAmapSchemasAmapCashComplete
    >($request);
  }

  @override
  Future<Response<void>> _amapUsersUserIdCashPatch({
    required String? userId,
    required CashEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Edit cash for an user. This will add the balance to the current balance.
A negative value can be provided to remove money from the user.

**The user must be a member of a group authorized to use manage AMAP to use this endpoint**''',
      summary: 'Edit Cash By Id',
      operationId: 'edit_cash_by_id_amap_users__user_id__cash_patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["AMAP"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/amap/users/${userId}/cash');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<OrderReturn>>> _amapUsersUserIdOrdersGet({
    required String? userId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get orders from an user.

**The user must be a member of the group AMAP to use this endpoint or can only access the endpoint for its own user_id**''',
      summary: 'Get Orders Of User',
      operationId: 'get_orders_of_user_amap_users__user_id__orders_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["AMAP"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/amap/users/${userId}/orders');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<OrderReturn>, OrderReturn>($request);
  }

  @override
  Future<Response<Information>> _amapInformationGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Return all information',
      summary: 'Get Information',
      operationId: 'get_information_amap_information_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["AMAP"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/amap/information');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<Information, Information>($request);
  }

  @override
  Future<Response<void>> _amapInformationPatch({
    required InformationEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Update information

**The user must be a member of a group authorized to use manage AMAP to use this endpoint**''',
      summary: 'Edit Information',
      operationId: 'edit_information_amap_information_patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["AMAP"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/amap/information');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<Manager>>> _bookingManagersGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get existing managers.

**This endpoint is only usable by administrators**''',
      summary: 'Get Managers',
      operationId: 'get_managers_booking_managers_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Booking"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/booking/managers');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<Manager>, Manager>($request);
  }

  @override
  Future<Response<Manager>> _bookingManagersPost({
    required ManagerBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a manager.

**This endpoint is only usable by administrators**''',
      summary: 'Create Manager',
      operationId: 'create_manager_booking_managers_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Booking"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/booking/managers');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<Manager, Manager>($request);
  }

  @override
  Future<Response<void>> _bookingManagersManagerIdPatch({
    required String? managerId,
    required ManagerUpdate? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Update a manager, the request should contain a JSON with the fields to change (not necessarily all fields) and their new value.

**This endpoint is only usable by administrators**''',
      summary: 'Update Manager',
      operationId: 'update_manager_booking_managers__manager_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Booking"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/booking/managers/${managerId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _bookingManagersManagerIdDelete({
    required String? managerId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Delete a manager only if the manager is not linked to any room

**This endpoint is only usable by administrators**''',
      summary: 'Delete Manager',
      operationId: 'delete_manager_booking_managers__manager_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Booking"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/booking/managers/${managerId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<Manager>>> _bookingManagersUsersMeGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Return all managers the current user is a member.

**The user must be authenticated to use this endpoint**''',
      summary: 'Get Current User Managers',
      operationId: 'get_current_user_managers_booking_managers_users_me_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Booking"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/booking/managers/users/me');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<Manager>, Manager>($request);
  }

  @override
  Future<Response<List<BookingReturnApplicant>>>
  _bookingBookingsUsersMeManageGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Return all bookings a user can manage.

**The user must be authenticated to use this endpoint**''',
      summary: 'Get Bookings For Manager',
      operationId:
          'get_bookings_for_manager_booking_bookings_users_me_manage_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Booking"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/booking/bookings/users/me/manage');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<BookingReturnApplicant>, BookingReturnApplicant>(
      $request,
    );
  }

  @override
  Future<Response<List<BookingReturnApplicant>>>
  _bookingBookingsConfirmedUsersMeManageGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Return all confirmed bookings a user can manage.
**The user must be authenticated to use this endpoint**''',
      summary: 'Get Confirmed Bookings For Manager',
      operationId:
          'get_confirmed_bookings_for_manager_booking_bookings_confirmed_users_me_manage_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Booking"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/booking/bookings/confirmed/users/me/manage');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<BookingReturnApplicant>, BookingReturnApplicant>(
      $request,
    );
  }

  @override
  Future<Response<List<BookingReturnSimpleApplicant>>>
  _bookingBookingsConfirmedGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Return all confirmed bookings.

**The user must be authenticated to use this endpoint**''',
      summary: 'Get Confirmed Bookings',
      operationId: 'get_confirmed_bookings_booking_bookings_confirmed_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Booking"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/booking/bookings/confirmed');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client
        .send<List<BookingReturnSimpleApplicant>, BookingReturnSimpleApplicant>(
          $request,
        );
  }

  @override
  Future<Response<List<BookingReturn>>> _bookingBookingsUsersMeGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get the user bookings.

**Only usable by the user**''',
      summary: 'Get Applicant Bookings',
      operationId: 'get_applicant_bookings_booking_bookings_users_me_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Booking"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/booking/bookings/users/me');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<BookingReturn>, BookingReturn>($request);
  }

  @override
  Future<Response<BookingReturn>> _bookingBookingsPost({
    required BookingBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a booking.

**The user must be authenticated to use this endpoint**''',
      summary: 'Create Booking',
      operationId: 'create_booking_booking_bookings_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Booking"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/booking/bookings');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<BookingReturn, BookingReturn>($request);
  }

  @override
  Future<Response<void>> _bookingBookingsBookingIdPatch({
    required String? bookingId,
    required BookingEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Edit a booking.

**Only usable by a user in the manager group of the booking or applicant before decision**''',
      summary: 'Edit Booking',
      operationId: 'edit_booking_booking_bookings__booking_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Booking"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/booking/bookings/${bookingId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _bookingBookingsBookingIdDelete({
    required String? bookingId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Remove a booking.

**Only usable by the applicant before decision**''',
      summary: 'Delete Booking',
      operationId: 'delete_booking_booking_bookings__booking_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Booking"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/booking/bookings/${bookingId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _bookingBookingsBookingIdReplyDecisionPatch({
    required String? bookingId,
    required String? decision,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Give a decision to a booking.

**Only usable by a user in the manager group of the booking**''',
      summary: 'Confirm Booking',
      operationId:
          'confirm_booking_booking_bookings__booking_id__reply__decision__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Booking"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/booking/bookings/${bookingId}/reply/${decision}',
    );
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<RoomComplete>>> _bookingRoomsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get all rooms.

**The user must be authenticated to use this endpoint**''',
      summary: 'Get Rooms',
      operationId: 'get_rooms_booking_rooms_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Booking"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/booking/rooms');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<RoomComplete>, RoomComplete>($request);
  }

  @override
  Future<Response<RoomComplete>> _bookingRoomsPost({
    required RoomBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a new room in database.

**This endpoint is only usable by admins**''',
      summary: 'Create Room',
      operationId: 'create_room_booking_rooms_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Booking"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/booking/rooms');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<RoomComplete, RoomComplete>($request);
  }

  @override
  Future<Response<void>> _bookingRoomsRoomIdPatch({
    required String? roomId,
    required RoomBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Edit a room.

**This endpoint is only usable by admins**''',
      summary: 'Edit Room',
      operationId: 'edit_room_booking_rooms__room_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Booking"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/booking/rooms/${roomId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _bookingRoomsRoomIdDelete({
    required String? roomId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Delete a room only if there are not future or ongoing bookings of this room

**This endpoint is only usable by admins**''',
      summary: 'Delete Room',
      operationId: 'delete_room_booking_rooms__room_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Booking"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/booking/rooms/${roomId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<SectionComplete>>> _campaignSectionsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Return sections in the database as a list of `schemas_campaign.SectionBase`

**The user must be a member of a group authorized to vote or to manage the campaign to use this endpoint**''',
      summary: 'Get Sections',
      operationId: 'get_sections_campaign_sections_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Campaign"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/campaign/sections');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<SectionComplete>, SectionComplete>($request);
  }

  @override
  Future<Response<SectionComplete>> _campaignSectionsPost({
    required SectionBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Add a section.

This endpoint can only be used in \'waiting\' status.

**The user must be a member of a group authorized to manage the campaign to use this endpoint**''',
      summary: 'Add Section',
      operationId: 'add_section_campaign_sections_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Campaign"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/campaign/sections');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<SectionComplete, SectionComplete>($request);
  }

  @override
  Future<Response<void>> _campaignSectionsSectionIdDelete({
    required String? sectionId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Delete a section.

This endpoint can only be used in \'waiting\' status.

**The user must be a member of a group authorized to manage the campaign to use this endpoint**''',
      summary: 'Delete Section',
      operationId: 'delete_section_campaign_sections__section_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Campaign"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/campaign/sections/${sectionId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<ListReturn>>> _campaignListsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Return campaign lists registered for the vote.

**The user must be a member of a group authorized to vote or to manage the campaign to use this endpoint**''',
      summary: 'Get Lists',
      operationId: 'get_lists_campaign_lists_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Campaign"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/campaign/lists');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<ListReturn>, ListReturn>($request);
  }

  @override
  Future<Response<ListReturn>> _campaignListsPost({
    required ListBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Add a campaign list to a section.

This endpoint can only be used in \'waiting\' status.

**The user must be a member of a group authorized to manage the campaign to use this endpoint**''',
      summary: 'Add List',
      operationId: 'add_list_campaign_lists_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Campaign"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/campaign/lists');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<ListReturn, ListReturn>($request);
  }

  @override
  Future<Response<void>> _campaignListsListIdDelete({
    required String? listId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Delete the campaign list with the given id.

This endpoint can only be used in \'waiting\' status.

**The user must be a member of a group authorized to manage the campaign to use this endpoint**''',
      summary: 'Delete List',
      operationId: 'delete_list_campaign_lists__list_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Campaign"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/campaign/lists/${listId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _campaignListsListIdPatch({
    required String? listId,
    required ListEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Update the campaign list with the given id.

This endpoint can only be used in \'waiting\' status.

**The user must be a member of a group authorized to manage the campaign to use this endpoint**''',
      summary: 'Update List',
      operationId: 'update_list_campaign_lists__list_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Campaign"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/campaign/lists/${listId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _campaignListsDelete({
    Object? listType,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Delete the all lists by type.

This endpoint can only be used in \'waiting\' status.

**The user must be a member of a group authorized to manage the campaign to use this endpoint**''',
      summary: 'Delete Lists By Type',
      operationId: 'delete_lists_by_type_campaign_lists__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Campaign"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/campaign/lists/');
    final Map<String, dynamic> $params = <String, dynamic>{
      'list_type': listType,
    };
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<CorePermission>> _campaignVotersGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Return the list of voters.

**The user must be a member of a group authorized to manage the campaign to use this endpoint**''',
      summary: 'Get Voters',
      operationId: 'get_voters_campaign_voters_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Campaign"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/campaign/voters');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<CorePermission, CorePermission>($request);
  }

  @override
  Future<Response<void>> _campaignVotersDelete({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Delete all voters.

**The user must be a member of a group authorized to manage the campaign to use this endpoint**''',
      summary: 'Delete Voters',
      operationId: 'delete_voters_campaign_voters_delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Campaign"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/campaign/voters');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _campaignVotersGroupIdPost({
    required String? groupId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Add a voter.

**The user must be a member of a group authorized to manage the campaign to use this endpoint**''',
      summary: 'Add Voter',
      operationId: 'add_voter_campaign_voters__group_id__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Campaign"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/campaign/voters/${groupId}');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _campaignVotersGroupIdDelete({
    required String? groupId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Delete a voter.

**The user must be a member of a group authorized to manage the campaign to use this endpoint**''',
      summary: 'Delete Voter',
      operationId: 'delete_voter_campaign_voters__group_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Campaign"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/campaign/voters/${groupId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _campaignStatusOpenPost({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''If the status is \'waiting\', change it to \'voting\' and create the blank lists.

> WARNING: this operation can not be reversed.
> When the status is \'open\', all users can vote and sections and lists can no longer be edited.

**The user must be a member of a group authorized to manage the campaign to use this endpoint**''',
      summary: 'Open Vote',
      operationId: 'open_vote_campaign_status_open_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Campaign"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/campaign/status/open');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _campaignStatusClosePost({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''If the status is \'open\', change it to \'closed\'.

> WARNING: this operation can not be reversed.
> When the status is \'closed\', users are no longer able to vote.

**The user must be a member of a group authorized to manage the campaign to use this endpoint**''',
      summary: 'Close Vote',
      operationId: 'close_vote_campaign_status_close_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Campaign"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/campaign/status/close');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _campaignStatusCountingPost({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''If the status is \'closed\', change it to \'counting\'.

> WARNING: this operation can not be reversed.
> When the status is \'counting\', administrators can see the results of the vote.

**The user must be a member of a group authorized to manage the campaign to use this endpoint**''',
      summary: 'Count Voting',
      operationId: 'count_voting_campaign_status_counting_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Campaign"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/campaign/status/counting');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _campaignStatusPublishedPost({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''If the status is \'counting\', change it to \'published\'.

> WARNING: this operation can not be reversed.
> When the status is \'published\', everyone can see the results of the vote.

**The user must be a member of a group authorized to manage the campaign to use this endpoint**''',
      summary: 'Publish Vote',
      operationId: 'publish_vote_campaign_status_published_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Campaign"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/campaign/status/published');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _campaignStatusResetPost({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Reset the vote. Can only be used if the current status is counting ou published.

> WARNING: This will delete all votes then put the module to Waiting status. This will also delete blank lists.

**The user must be a member of a group authorized to manage the campaign to use this endpoint**''',
      summary: 'Reset Vote',
      operationId: 'reset_vote_campaign_status_reset_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Campaign"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/campaign/status/reset');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<String>>> _campaignVotesGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Return the list of id of sections an user has already voted for.

**The user must be a member of a group authorized to vote to use this endpoint**''',
      summary: 'Get Sections Already Voted',
      operationId: 'get_sections_already_voted_campaign_votes_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Campaign"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/campaign/votes');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<String>, String>($request);
  }

  @override
  Future<Response<void>> _campaignVotesPost({
    required VoteBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Add a vote for a given campaign list.

An user can only vote for one list per section.

**The user must be a member of a group authorized to vote to use this endpoint**''',
      summary: 'Vote',
      operationId: 'vote_campaign_votes_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Campaign"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/campaign/votes');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<AppModulesCampaignSchemasCampaignResult>>>
  _campaignResultsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Return the results of the vote.

**The user must be a member of a group authorized to vote or to manage the campaign to use this endpoint**''',
      summary: 'Get Results',
      operationId: 'get_results_campaign_results_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Campaign"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/campaign/results');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<
      List<AppModulesCampaignSchemasCampaignResult>,
      AppModulesCampaignSchemasCampaignResult
    >($request);
  }

  @override
  Future<Response<VoteStatus>> _campaignStatusGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get the current status of the vote.

**The user must be a member of a group authorized to vote or to manage the campaign to use this endpoint**''',
      summary: 'Get Status Vote',
      operationId: 'get_status_vote_campaign_status_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Campaign"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/campaign/status');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<VoteStatus, VoteStatus>($request);
  }

  @override
  Future<Response<VoteStats>> _campaignStatsSectionIdGet({
    required String? sectionId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get stats about a given section.

**The user must be authorized to vote to use this endpoint**''',
      summary: 'Get Stats For Section',
      operationId: 'get_stats_for_section_campaign_stats__section_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Campaign"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/campaign/stats/${sectionId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<VoteStats, VoteStats>($request);
  }

  @override
  Future<Response<AppTypesStandardResponsesResult>>
  _campaignListsListIdLogoPost({
    required String? listId,
    required List<int> image,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Upload a logo for a campaign list.

**The user must be authorized to manage the campaign to use this endpoint**''',
      summary: 'Create Campaigns Logo',
      operationId: 'create_campaigns_logo_campaign_lists__list_id__logo_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Campaign"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/campaign/lists/${listId}/logo');
    final List<PartValue> $parts = <PartValue>[
      PartValueFile<List<int>>('image', image),
    ];
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parts: $parts,
      multipart: true,
      tag: swaggerMetaData,
    );
    return client
        .send<AppTypesStandardResponsesResult, AppTypesStandardResponsesResult>(
          $request,
        );
  }

  @override
  Future<Response<List<int>>> _campaignListsListIdLogoGet({
    required String? listId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get the logo of a campaign list.
**The user must be a member of a group authorized to vote or to manage the campaign to use this endpoint**''',
      summary: 'Read Campaigns Logo',
      operationId: 'read_campaigns_logo_campaign_lists__list_id__logo_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Campaign"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/campaign/lists/${listId}/logo');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<int>, int>($request);
  }

  @override
  Future<Response<List<CdrUserPreview>>> _cdrUsersGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get all users.

**User must be part of a seller group to use this endpoint**''',
      summary: 'Get Cdr Users',
      operationId: 'get_cdr_users_cdr_users__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/users/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<CdrUserPreview>, CdrUserPreview>($request);
  }

  @override
  Future<Response<List<CdrUserPreview>>> _cdrUsersPendingGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get all users that have non-validated purchases.

**User must be part of a seller group to use this endpoint**''',
      summary: 'Get Cdr Users Pending Validation',
      operationId: 'get_cdr_users_pending_validation_cdr_users_pending__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/users/pending/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<CdrUserPreview>, CdrUserPreview>($request);
  }

  @override
  Future<Response<CdrUser>> _cdrUsersUserIdGet({
    required String? userId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get a user.

**User must be part of a seller group or trying to get itself to use this endpoint**''',
      summary: 'Get Cdr User',
      operationId: 'get_cdr_user_cdr_users__user_id___get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/users/${userId}/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<CdrUser, CdrUser>($request);
  }

  @override
  Future<Response<void>> _cdrUsersUserIdPatch({
    required String? userId,
    required CdrUserUpdate? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Edit a user email, nickname and/or floor.

An email will be send to the user, to confirm its new address.

**User must be part of a seller group to use this endpoint**''',
      summary: 'Update Cdr User',
      operationId: 'update_cdr_user_cdr_users__user_id___patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/users/${userId}/');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<SellerComplete>>> _cdrSellersGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get all sellers.

**User must be CDR Admin to use this endpoint**''',
      summary: 'Get Sellers',
      operationId: 'get_sellers_cdr_sellers__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/sellers/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<SellerComplete>, SellerComplete>($request);
  }

  @override
  Future<Response<SellerComplete>> _cdrSellersPost({
    required SellerBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a seller.

**User must be CDR Admin to use this endpoint**''',
      summary: 'Create Seller',
      operationId: 'create_seller_cdr_sellers__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/sellers/');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<SellerComplete, SellerComplete>($request);
  }

  @override
  Future<Response<List<SellerComplete>>> _cdrUsersMeSellersGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Get sellers user is part of the group. If user is adminCDR, returns all sellers.

**User must be authenticated to use this endpoint**''',
      summary: 'Get Sellers By User Id',
      operationId: 'get_sellers_by_user_id_cdr_users_me_sellers__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/users/me/sellers/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<SellerComplete>, SellerComplete>($request);
  }

  @override
  Future<Response<List<SellerComplete>>> _cdrOnlineSellersGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get all sellers that has online available products.

**User must be authenticated to use this endpoint**''',
      summary: 'Get Online Sellers',
      operationId: 'get_online_sellers_cdr_online_sellers__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/online/sellers/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<SellerComplete>, SellerComplete>($request);
  }

  @override
  Future<Response<List<int>>> _cdrSellersSellerIdResultsGet({
    required String? sellerId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get a seller\'s results.

**User must be CDR Admin to use this endpoint**''',
      summary: 'Send Seller Results',
      operationId: 'send_seller_results_cdr_sellers__seller_id__results__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/sellers/${sellerId}/results/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<int>, int>($request);
  }

  @override
  Future<Response<List<AppModulesCdrSchemasCdrProductComplete>>>
  _cdrOnlineProductsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get a seller\'s online available products.

**User must be authenticated to use this endpoint**''',
      summary: 'Get All Available Online Products',
      operationId: 'get_all_available_online_products_cdr_online_products__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/online/products/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<
      List<AppModulesCdrSchemasCdrProductComplete>,
      AppModulesCdrSchemasCdrProductComplete
    >($request);
  }

  @override
  Future<Response<List<AppModulesCdrSchemasCdrProductComplete>>>
  _cdrProductsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get a seller\'s online available products.

**User must be part of a seller group to use this endpoint**''',
      summary: 'Get All Products',
      operationId: 'get_all_products_cdr_products__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/products/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<
      List<AppModulesCdrSchemasCdrProductComplete>,
      AppModulesCdrSchemasCdrProductComplete
    >($request);
  }

  @override
  Future<Response<void>> _cdrSellersSellerIdPatch({
    required String? sellerId,
    required SellerEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Update a seller.

**User must be CDR Admin to use this endpoint**''',
      summary: 'Update Seller',
      operationId: 'update_seller_cdr_sellers__seller_id___patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/sellers/${sellerId}/');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _cdrSellersSellerIdDelete({
    required String? sellerId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Delete a seller.

**User must be CDR Admin to use this endpoint**''',
      summary: 'Delete Seller',
      operationId: 'delete_seller_cdr_sellers__seller_id___delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/sellers/${sellerId}/');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<AppModulesCdrSchemasCdrProductComplete>>>
  _cdrSellersSellerIdProductsGet({
    required String? sellerId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get a seller\'s products.

**User must be part of the seller\'s group to use this endpoint**''',
      summary: 'Get Products By Seller Id',
      operationId:
          'get_products_by_seller_id_cdr_sellers__seller_id__products__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/sellers/${sellerId}/products/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<
      List<AppModulesCdrSchemasCdrProductComplete>,
      AppModulesCdrSchemasCdrProductComplete
    >($request);
  }

  @override
  Future<Response<AppModulesCdrSchemasCdrProductComplete>>
  _cdrSellersSellerIdProductsPost({
    required String? sellerId,
    required AppModulesCdrSchemasCdrProductBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a product.

**User must be part of the seller\'s group to use this endpoint**''',
      summary: 'Create Product',
      operationId: 'create_product_cdr_sellers__seller_id__products__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/sellers/${sellerId}/products/');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<
      AppModulesCdrSchemasCdrProductComplete,
      AppModulesCdrSchemasCdrProductComplete
    >($request);
  }

  @override
  Future<Response<List<AppModulesCdrSchemasCdrProductComplete>>>
  _cdrOnlineSellersSellerIdProductsGet({
    required String? sellerId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get a seller\'s online available products.

**User must be authenticated to use this endpoint**''',
      summary: 'Get Available Online Products',
      operationId:
          'get_available_online_products_cdr_online_sellers__seller_id__products__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/online/sellers/${sellerId}/products/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<
      List<AppModulesCdrSchemasCdrProductComplete>,
      AppModulesCdrSchemasCdrProductComplete
    >($request);
  }

  @override
  Future<Response<void>> _cdrSellersSellerIdProductsProductIdPatch({
    required String? sellerId,
    required String? productId,
    required AppModulesCdrSchemasCdrProductEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Edit a product.

**User must be part of the seller\'s group to use this endpoint**''',
      summary: 'Update Product',
      operationId:
          'update_product_cdr_sellers__seller_id__products__product_id___patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/cdr/sellers/${sellerId}/products/${productId}/',
    );
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _cdrSellersSellerIdProductsProductIdDelete({
    required String? sellerId,
    required String? productId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Delete a product.

**User must be part of the seller\'s group to use this endpoint**''',
      summary: 'Delete Product',
      operationId:
          'delete_product_cdr_sellers__seller_id__products__product_id___delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/cdr/sellers/${sellerId}/products/${productId}/',
    );
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<AppModulesCdrSchemasCdrProductVariantComplete>>
  _cdrSellersSellerIdProductsProductIdVariantsPost({
    required String? sellerId,
    required String? productId,
    required AppModulesCdrSchemasCdrProductVariantBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a product variant.

**User must be part of the seller\'s group to use this endpoint**''',
      summary: 'Create Product Variant',
      operationId:
          'create_product_variant_cdr_sellers__seller_id__products__product_id__variants__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/cdr/sellers/${sellerId}/products/${productId}/variants/',
    );
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<
      AppModulesCdrSchemasCdrProductVariantComplete,
      AppModulesCdrSchemasCdrProductVariantComplete
    >($request);
  }

  @override
  Future<Response<void>>
  _cdrSellersSellerIdProductsProductIdVariantsVariantIdPatch({
    required String? sellerId,
    required String? productId,
    required String? variantId,
    required AppModulesCdrSchemasCdrProductVariantEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Edit a product variant.

**User must be part of the seller\'s group to use this endpoint**''',
      summary: 'Update Product Variant',
      operationId:
          'update_product_variant_cdr_sellers__seller_id__products__product_id__variants__variant_id___patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/cdr/sellers/${sellerId}/products/${productId}/variants/${variantId}/',
    );
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>>
  _cdrSellersSellerIdProductsProductIdVariantsVariantIdDelete({
    required String? sellerId,
    required String? productId,
    required String? variantId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Delete a product variant.

**User must be part of the seller\'s group to use this endpoint**''',
      summary: 'Delete Product Variant',
      operationId:
          'delete_product_variant_cdr_sellers__seller_id__products__product_id__variants__variant_id___delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/cdr/sellers/${sellerId}/products/${productId}/variants/${variantId}/',
    );
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<DocumentComplete>>> _cdrSellersSellerIdDocumentsGet({
    required String? sellerId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get a seller\'s documents.

**User must be part of the seller\'s group to use this endpoint**''',
      summary: 'Get Seller Documents',
      operationId:
          'get_seller_documents_cdr_sellers__seller_id__documents__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/sellers/${sellerId}/documents/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<DocumentComplete>, DocumentComplete>($request);
  }

  @override
  Future<Response<DocumentComplete>> _cdrSellersSellerIdDocumentsPost({
    required String? sellerId,
    required DocumentBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a document.

**User must be part of the seller\'s group to use this endpoint**''',
      summary: 'Create Document',
      operationId: 'create_document_cdr_sellers__seller_id__documents__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/sellers/${sellerId}/documents/');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<DocumentComplete, DocumentComplete>($request);
  }

  @override
  Future<Response<List<DocumentComplete>>> _cdrDocumentsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get a seller\'s documents.

**User must be part of a seller\'s group to use this endpoint**''',
      summary: 'Get All Sellers Documents',
      operationId: 'get_all_sellers_documents_cdr_documents__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/documents/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<DocumentComplete>, DocumentComplete>($request);
  }

  @override
  Future<Response<void>> _cdrSellersSellerIdDocumentsDocumentIdDelete({
    required String? sellerId,
    required String? documentId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Delete a document.

**User must be part of the seller\'s group to use this endpoint**''',
      summary: 'Delete Document',
      operationId:
          'delete_document_cdr_sellers__seller_id__documents__document_id___delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/cdr/sellers/${sellerId}/documents/${documentId}/',
    );
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<PurchaseReturn>>> _cdrUsersUserIdPurchasesGet({
    required String? userId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get a user\'s purchases.

**User must get his own purchases or be CDR Admin to use this endpoint**''',
      summary: 'Get Purchases By User Id',
      operationId:
          'get_purchases_by_user_id_cdr_users__user_id__purchases__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/users/${userId}/purchases/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<PurchaseReturn>, PurchaseReturn>($request);
  }

  @override
  Future<Response<List<PurchaseReturn>>> _cdrMePurchasesGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get My Purchases',
      operationId: 'get_my_purchases_cdr_me_purchases__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/me/purchases/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<PurchaseReturn>, PurchaseReturn>($request);
  }

  @override
  Future<Response<List<PurchaseReturn>>> _cdrMePurchasesAllGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get All My Purchases',
      operationId: 'get_all_my_purchases_cdr_me_purchases_all_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/me/purchases/all');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<PurchaseReturn>, PurchaseReturn>($request);
  }

  @override
  Future<Response<List<PurchaseReturn>>>
  _cdrSellersSellerIdUsersUserIdPurchasesGet({
    required String? sellerId,
    required String? userId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get a user\'s purchases.

**User must get his own purchases or be part of the seller\'s group to use this endpoint**''',
      summary: 'Get Purchases By User Id By Seller Id',
      operationId:
          'get_purchases_by_user_id_by_seller_id_cdr_sellers__seller_id__users__user_id__purchases__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/cdr/sellers/${sellerId}/users/${userId}/purchases/',
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<PurchaseReturn>, PurchaseReturn>($request);
  }

  @override
  Future<Response<AppModulesCdrSchemasCdrPurchaseComplete>>
  _cdrUsersUserIdPurchasesProductVariantIdPost({
    required String? userId,
    required String? productVariantId,
    required AppModulesCdrSchemasCdrPurchaseBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a purchase.

**User must create a purchase for themself and for an online available product or be part of the seller\'s group to use this endpoint**''',
      summary: 'Create Purchase',
      operationId:
          'create_purchase_cdr_users__user_id__purchases__product_variant_id___post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/cdr/users/${userId}/purchases/${productVariantId}/',
    );
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<
      AppModulesCdrSchemasCdrPurchaseComplete,
      AppModulesCdrSchemasCdrPurchaseComplete
    >($request);
  }

  @override
  Future<Response<void>> _cdrUsersUserIdPurchasesProductVariantIdDelete({
    required String? userId,
    required String? productVariantId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Delete a purchase.

**User must create a purchase for themself and for an online available product or be part of the seller\'s group to use this endpoint**''',
      summary: 'Delete Purchase',
      operationId:
          'delete_purchase_cdr_users__user_id__purchases__product_variant_id___delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/cdr/users/${userId}/purchases/${productVariantId}/',
    );
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _cdrBatchPurchasesPost({
    required BatchPurchase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a purchase for a list of user.

**User must be part of the seller\'s group to use this endpoint**''',
      summary: 'Create Purchase Batch',
      operationId: 'create_purchase_batch_cdr_batch_purchases__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/batch-purchases/');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>>
  _cdrUsersUserIdPurchasesProductVariantIdValidatedPatch({
    required String? userId,
    required String? productVariantId,
    required bool? validated,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Validate a purchase.

**User must be CDR Admin to use this endpoint**''',
      summary: 'Mark Purchase As Validated',
      operationId:
          'mark_purchase_as_validated_cdr_users__user_id__purchases__product_variant_id__validated__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/cdr/users/${userId}/purchases/${productVariantId}/validated/',
    );
    final Map<String, dynamic> $params = <String, dynamic>{
      'validated': validated,
    };
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _cdrBatchValidationPost({
    required BatchValidation? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Validate Purchase Batch',
      operationId: 'validate_purchase_batch_cdr_batch_validation__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/batch-validation/');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<SignatureComplete>>> _cdrUsersUserIdSignaturesGet({
    required String? userId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get a user\'s signatures.

**User must get his own signatures or be CDR Admin to use this endpoint**''',
      summary: 'Get Signatures By User Id',
      operationId:
          'get_signatures_by_user_id_cdr_users__user_id__signatures__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/users/${userId}/signatures/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<SignatureComplete>, SignatureComplete>($request);
  }

  @override
  Future<Response<List<SignatureComplete>>>
  _cdrSellersSellerIdUsersUserIdSignaturesGet({
    required String? sellerId,
    required String? userId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get a user\'s signatures for a single seller.

**User must get his own signatures or be part of the seller\'s group to use this endpoint**''',
      summary: 'Get Signatures By User Id By Seller Id',
      operationId:
          'get_signatures_by_user_id_by_seller_id_cdr_sellers__seller_id__users__user_id__signatures__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/cdr/sellers/${sellerId}/users/${userId}/signatures/',
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<SignatureComplete>, SignatureComplete>($request);
  }

  @override
  Future<Response<SignatureComplete>> _cdrUsersUserIdSignaturesDocumentIdPost({
    required String? userId,
    required String? documentId,
    required SignatureBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a signature.

**User must sign numerically or be part of the seller\'s group to use this endpoint**''',
      summary: 'Create Signature',
      operationId:
          'create_signature_cdr_users__user_id__signatures__document_id___post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/cdr/users/${userId}/signatures/${documentId}/',
    );
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<SignatureComplete, SignatureComplete>($request);
  }

  @override
  Future<Response<void>> _cdrUsersUserIdSignaturesDocumentIdDelete({
    required String? userId,
    required String? documentId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Delete a signature.

**User must be CDR Admin to use this endpoint**''',
      summary: 'Delete Signature',
      operationId:
          'delete_signature_cdr_users__user_id__signatures__document_id___delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/cdr/users/${userId}/signatures/${documentId}/',
    );
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<CurriculumComplete>>> _cdrCurriculumsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get all curriculums.

**User be authenticated to use this endpoint**''',
      summary: 'Get Curriculums',
      operationId: 'get_curriculums_cdr_curriculums__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/curriculums/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<CurriculumComplete>, CurriculumComplete>($request);
  }

  @override
  Future<Response<CurriculumComplete>> _cdrCurriculumsPost({
    required CurriculumBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a curriculum.

**User must be CDR Admin to use this endpoint**''',
      summary: 'Create Curriculum',
      operationId: 'create_curriculum_cdr_curriculums__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/curriculums/');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<CurriculumComplete, CurriculumComplete>($request);
  }

  @override
  Future<Response<void>> _cdrCurriculumsCurriculumIdDelete({
    required String? curriculumId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Delete a curriculum.

**User must be CDR Admin to use this endpoint**''',
      summary: 'Delete Curriculum',
      operationId: 'delete_curriculum_cdr_curriculums__curriculum_id___delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/curriculums/${curriculumId}/');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _cdrUsersUserIdCurriculumsCurriculumIdPost({
    required String? userId,
    required String? curriculumId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Add a curriculum to a user.

**User must add a curriculum to themself or be CDR Admin to use this endpoint**''',
      summary: 'Create Curriculum Membership',
      operationId:
          'create_curriculum_membership_cdr_users__user_id__curriculums__curriculum_id___post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/cdr/users/${userId}/curriculums/${curriculumId}/',
    );
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _cdrUsersUserIdCurriculumsCurriculumIdPatch({
    required String? userId,
    required String? curriculumId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Update a curriculum membership.

**User must add a curriculum to themself or be CDR Admin to use this endpoint**''',
      summary: 'Update Curriculum Membership',
      operationId:
          'update_curriculum_membership_cdr_users__user_id__curriculums__curriculum_id___patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/cdr/users/${userId}/curriculums/${curriculumId}/',
    );
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _cdrUsersUserIdCurriculumsCurriculumIdDelete({
    required String? userId,
    required String? curriculumId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Remove a curriculum from a user.

**User must add a curriculum to themself or be CDR Admin to use this endpoint**''',
      summary: 'Delete Curriculum Membership',
      operationId:
          'delete_curriculum_membership_cdr_users__user_id__curriculums__curriculum_id___delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/cdr/users/${userId}/curriculums/${curriculumId}/',
    );
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<AppModulesCdrSchemasCdrPaymentComplete>>>
  _cdrUsersUserIdPaymentsGet({
    required String? userId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get a user\'s payments.

**User must get his own payments or be CDR Admin to use this endpoint**''',
      summary: 'Get Payments By User Id',
      operationId: 'get_payments_by_user_id_cdr_users__user_id__payments__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/users/${userId}/payments/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<
      List<AppModulesCdrSchemasCdrPaymentComplete>,
      AppModulesCdrSchemasCdrPaymentComplete
    >($request);
  }

  @override
  Future<Response<AppModulesCdrSchemasCdrPaymentComplete>>
  _cdrUsersUserIdPaymentsPost({
    required String? userId,
    required AppModulesCdrSchemasCdrPaymentBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a payment.

**User must be CDR Admin to use this endpoint**''',
      summary: 'Create Payment',
      operationId: 'create_payment_cdr_users__user_id__payments__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/users/${userId}/payments/');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<
      AppModulesCdrSchemasCdrPaymentComplete,
      AppModulesCdrSchemasCdrPaymentComplete
    >($request);
  }

  @override
  Future<Response<void>> _cdrUsersUserIdPaymentsPaymentIdDelete({
    required String? userId,
    required String? paymentId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Remove a payment.

**User must be CDR Admin to use this endpoint**''',
      summary: 'Delete Payment',
      operationId:
          'delete_payment_cdr_users__user_id__payments__payment_id___delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/users/${userId}/payments/${paymentId}/');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<PaymentUrl>> _cdrPayPost({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get payment url',
      summary: 'Get Payment Url',
      operationId: 'get_payment_url_cdr_pay__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/pay/');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<PaymentUrl, PaymentUrl>($request);
  }

  @override
  Future<Response<CdrYear>> _cdrYearGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Cdr Year',
      operationId: 'get_cdr_year_cdr_year__get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/year/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<CdrYear, CdrYear>($request);
  }

  @override
  Future<Response<void>> _cdrYearPatch({
    required CdrYear? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Update Cdr Year',
      operationId: 'update_cdr_year_cdr_year__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/year/');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<Status>> _cdrStatusGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Status',
      operationId: 'get_status_cdr_status__get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/status/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<Status, Status>($request);
  }

  @override
  Future<Response<void>> _cdrStatusPatch({
    required Status? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Update Status',
      operationId: 'update_status_cdr_status__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/status/');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<AppModulesCdrSchemasCdrTicket>>> _cdrUsersMeTicketsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get My Tickets',
      operationId: 'get_my_tickets_cdr_users_me_tickets__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/users/me/tickets/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<
      List<AppModulesCdrSchemasCdrTicket>,
      AppModulesCdrSchemasCdrTicket
    >($request);
  }

  @override
  Future<Response<List<AppModulesCdrSchemasCdrTicket>>>
  _cdrUsersUserIdTicketsGet({
    required String? userId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Tickets Of User',
      operationId: 'get_tickets_of_user_cdr_users__user_id__tickets__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/users/${userId}/tickets/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<
      List<AppModulesCdrSchemasCdrTicket>,
      AppModulesCdrSchemasCdrTicket
    >($request);
  }

  @override
  Future<Response<TicketSecret>> _cdrUsersMeTicketsTicketIdSecretGet({
    required String? ticketId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Ticket Secret',
      operationId:
          'get_ticket_secret_cdr_users_me_tickets__ticket_id__secret__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cdr/users/me/tickets/${ticketId}/secret/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<TicketSecret, TicketSecret>($request);
  }

  @override
  Future<Response<AppModulesCdrSchemasCdrTicket>>
  _cdrSellersSellerIdProductsProductIdTicketsGeneratorIdSecretGet({
    required String? sellerId,
    required String? productId,
    required String? generatorId,
    required String? secret,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Ticket By Secret',
      operationId:
          'get_ticket_by_secret_cdr_sellers__seller_id__products__product_id__tickets__generator_id___secret___get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/cdr/sellers/${sellerId}/products/${productId}/tickets/${generatorId}/${secret}/',
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client
        .send<AppModulesCdrSchemasCdrTicket, AppModulesCdrSchemasCdrTicket>(
          $request,
        );
  }

  @override
  Future<Response<void>>
  _cdrSellersSellerIdProductsProductIdTicketsGeneratorIdSecretPatch({
    required String? sellerId,
    required String? productId,
    required String? generatorId,
    required String? secret,
    required TicketScan? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Scan Ticket',
      operationId:
          'scan_ticket_cdr_sellers__seller_id__products__product_id__tickets__generator_id___secret___patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/cdr/sellers/${sellerId}/products/${productId}/tickets/${generatorId}/${secret}/',
    );
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<CoreUserSimple>>>
  _cdrSellersSellerIdProductsProductIdTicketsGeneratorIdListsTagGet({
    required String? sellerId,
    required String? productId,
    required String? generatorId,
    required String? tag,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Users By Tag',
      operationId:
          'get_users_by_tag_cdr_sellers__seller_id__products__product_id__tickets__generator_id__lists__tag___get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/cdr/sellers/${sellerId}/products/${productId}/tickets/${generatorId}/lists/${tag}/',
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<CoreUserSimple>, CoreUserSimple>($request);
  }

  @override
  Future<Response<List<String>>>
  _cdrSellersSellerIdProductsProductIdTagsGeneratorIdGet({
    required String? sellerId,
    required String? productId,
    required String? generatorId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Tags Of Ticket',
      operationId:
          'get_tags_of_ticket_cdr_sellers__seller_id__products__product_id__tags__generator_id___get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/cdr/sellers/${sellerId}/products/${productId}/tags/${generatorId}/',
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<String>, String>($request);
  }

  @override
  Future<Response<AppModulesCdrSchemasCdrProductComplete>>
  _cdrSellersSellerIdProductsProductIdTicketsPost({
    required String? sellerId,
    required String? productId,
    required GenerateTicketBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Generate Ticket For Product',
      operationId:
          'generate_ticket_for_product_cdr_sellers__seller_id__products__product_id__tickets__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/cdr/sellers/${sellerId}/products/${productId}/tickets/',
    );
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<
      AppModulesCdrSchemasCdrProductComplete,
      AppModulesCdrSchemasCdrProductComplete
    >($request);
  }

  @override
  Future<Response<void>>
  _cdrSellersSellerIdProductsProductIdTicketsTicketGeneratorIdDelete({
    required String? sellerId,
    required String? productId,
    required String? ticketGeneratorId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Delete Ticket Generator For Product',
      operationId:
          'delete_ticket_generator_for_product_cdr_sellers__seller_id__products__product_id__tickets__ticket_generator_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/cdr/sellers/${sellerId}/products/${productId}/tickets/${ticketGeneratorId}',
    );
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<CustomDataFieldComplete>>>
  _cdrSellersSellerIdProductsProductIdDataGet({
    required String? sellerId,
    required String? productId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Custom Data Fields',
      operationId:
          'get_custom_data_fields_cdr_sellers__seller_id__products__product_id__data__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/cdr/sellers/${sellerId}/products/${productId}/data/',
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<CustomDataFieldComplete>, CustomDataFieldComplete>(
      $request,
    );
  }

  @override
  Future<Response<CustomDataFieldComplete>>
  _cdrSellersSellerIdProductsProductIdDataPost({
    required String? sellerId,
    required String? productId,
    required CustomDataFieldBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Create Custom Data Field',
      operationId:
          'create_custom_data_field_cdr_sellers__seller_id__products__product_id__data__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/cdr/sellers/${sellerId}/products/${productId}/data/',
    );
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<CustomDataFieldComplete, CustomDataFieldComplete>(
      $request,
    );
  }

  @override
  Future<Response<void>> _cdrSellersSellerIdProductsProductIdDataFieldIdPatch({
    required String? sellerId,
    required String? productId,
    required String? fieldId,
    required CustomDataFieldBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Update Custom Data Field',
      operationId:
          'update_custom_data_field_cdr_sellers__seller_id__products__product_id__data__field_id___patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/cdr/sellers/${sellerId}/products/${productId}/data/${fieldId}/',
    );
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _cdrSellersSellerIdProductsProductIdDataFieldIdDelete({
    required String? sellerId,
    required String? productId,
    required String? fieldId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Delete Customdata Field',
      operationId:
          'delete_customdata_field_cdr_sellers__seller_id__products__product_id__data__field_id___delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/cdr/sellers/${sellerId}/products/${productId}/data/${fieldId}/',
    );
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<CustomDataComplete>>
  _cdrSellersSellerIdProductsProductIdUsersUserIdDataFieldIdGet({
    required String? sellerId,
    required String? productId,
    required String? userId,
    required String? fieldId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Customdata',
      operationId:
          'get_customdata_cdr_sellers__seller_id__products__product_id__users__user_id__data__field_id___get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/cdr/sellers/${sellerId}/products/${productId}/users/${userId}/data/${fieldId}/',
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<CustomDataComplete, CustomDataComplete>($request);
  }

  @override
  Future<Response<CustomDataComplete>>
  _cdrSellersSellerIdProductsProductIdUsersUserIdDataFieldIdPost({
    required String? sellerId,
    required String? productId,
    required String? userId,
    required String? fieldId,
    required CustomDataBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Create Custom Data',
      operationId:
          'create_custom_data_cdr_sellers__seller_id__products__product_id__users__user_id__data__field_id___post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/cdr/sellers/${sellerId}/products/${productId}/users/${userId}/data/${fieldId}/',
    );
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<CustomDataComplete, CustomDataComplete>($request);
  }

  @override
  Future<Response<void>>
  _cdrSellersSellerIdProductsProductIdUsersUserIdDataFieldIdPatch({
    required String? sellerId,
    required String? productId,
    required String? userId,
    required String? fieldId,
    required CustomDataBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Update Custom Data',
      operationId:
          'update_custom_data_cdr_sellers__seller_id__products__product_id__users__user_id__data__field_id___patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/cdr/sellers/${sellerId}/products/${productId}/users/${userId}/data/${fieldId}/',
    );
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>>
  _cdrSellersSellerIdProductsProductIdUsersUserIdDataFieldIdDelete({
    required String? sellerId,
    required String? productId,
    required String? userId,
    required String? fieldId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Delete Customdata',
      operationId:
          'delete_customdata_cdr_sellers__seller_id__products__product_id__users__user_id__data__field_id___delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cdr"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/cdr/sellers/${sellerId}/products/${productId}/users/${userId}/data/${fieldId}/',
    );
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<TheMovieDB>> _cinemaThemoviedbThemoviedbIdGet({
    required String? themoviedbId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Makes a HTTP request to The Movie Database (TMDB)
using an API key and returns a TheMovieDB object
* https://developer.themoviedb.org/reference/movie-details
* https://developer.themoviedb.org/docs/errors''',
      summary: 'Get Movie',
      operationId: 'get_movie_cinema_themoviedb__themoviedb_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cinema"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cinema/themoviedb/${themoviedbId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<TheMovieDB, TheMovieDB>($request);
  }

  @override
  Future<Response<List<CineSessionComplete>>> _cinemaSessionsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Sessions',
      operationId: 'get_sessions_cinema_sessions_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cinema"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cinema/sessions');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<CineSessionComplete>, CineSessionComplete>(
      $request,
    );
  }

  @override
  Future<Response<CineSessionComplete>> _cinemaSessionsPost({
    required CineSessionBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Create Session',
      operationId: 'create_session_cinema_sessions_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cinema"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cinema/sessions');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<CineSessionComplete, CineSessionComplete>($request);
  }

  @override
  Future<Response<dynamic>> _cinemaSessionsSessionIdPatch({
    required String? sessionId,
    required CineSessionUpdate? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Update Session',
      operationId: 'update_session_cinema_sessions__session_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cinema"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cinema/sessions/${sessionId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<void>> _cinemaSessionsSessionIdDelete({
    required String? sessionId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Delete Session',
      operationId: 'delete_session_cinema_sessions__session_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cinema"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cinema/sessions/${sessionId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<AppTypesStandardResponsesResult>>
  _cinemaSessionsSessionIdPosterPost({
    required String? sessionId,
    required List<int> image,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Create Campaigns Logo',
      operationId:
          'create_campaigns_logo_cinema_sessions__session_id__poster_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cinema"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cinema/sessions/${sessionId}/poster');
    final List<PartValue> $parts = <PartValue>[
      PartValueFile<List<int>>('image', image),
    ];
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parts: $parts,
      multipart: true,
      tag: swaggerMetaData,
    );
    return client
        .send<AppTypesStandardResponsesResult, AppTypesStandardResponsesResult>(
          $request,
        );
  }

  @override
  Future<Response<List<int>>> _cinemaSessionsSessionIdPosterGet({
    required String? sessionId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Read Session Poster',
      operationId:
          'read_session_poster_cinema_sessions__session_id__poster_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Cinema"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/cinema/sessions/${sessionId}/poster');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<int>, int>($request);
  }

  @override
  Future<Response<List<RaffleComplete>>> _tombolaRafflesGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Return all raffles',
      summary: 'Get Raffle',
      operationId: 'get_raffle_tombola_raffles_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raffle"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tombola/raffles');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<RaffleComplete>, RaffleComplete>($request);
  }

  @override
  Future<Response<RaffleComplete>> _tombolaRafflesPost({
    required RaffleBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a new raffle

**The user must be a member of the group admin to use this endpoint**''',
      summary: 'Create Raffle',
      operationId: 'create_raffle_tombola_raffles_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raffle"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tombola/raffles');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<RaffleComplete, RaffleComplete>($request);
  }

  @override
  Future<Response<void>> _tombolaRafflesRaffleIdPatch({
    required String? raffleId,
    required RaffleEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Edit a raffle

**The user must be a member of the raffle\'s group to use this endpoint**''',
      summary: 'Edit Raffle',
      operationId: 'edit_raffle_tombola_raffles__raffle_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raffle"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tombola/raffles/${raffleId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _tombolaRafflesRaffleIdDelete({
    required String? raffleId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Delete a raffle.

**The user must be a member of the raffle\'s group to use this endpoint**''',
      summary: 'Delete Raffle',
      operationId: 'delete_raffle_tombola_raffles__raffle_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raffle"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tombola/raffles/${raffleId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<RaffleComplete>>> _tombolaGroupGroupIdRafflesGet({
    required String? groupId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Return all raffles from a group',
      summary: 'Get Raffles By Group Id',
      operationId:
          'get_raffles_by_group_id_tombola_group__group_id__raffles_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raffle"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tombola/group/${groupId}/raffles');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<RaffleComplete>, RaffleComplete>($request);
  }

  @override
  Future<Response<RaffleStats>> _tombolaRafflesRaffleIdStatsGet({
    required String? raffleId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Return the number of ticket sold and the total amount recollected for a raffle',
      summary: 'Get Raffle Stats',
      operationId: 'get_raffle_stats_tombola_raffles__raffle_id__stats_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raffle"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tombola/raffles/${raffleId}/stats');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<RaffleStats, RaffleStats>($request);
  }

  @override
  Future<Response<AppTypesStandardResponsesResult>>
  _tombolaRafflesRaffleIdLogoPost({
    required String? raffleId,
    required List<int> image,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Upload a logo for a specific raffle.

**The user must be a member of the raffle\'s group to use this endpoint**''',
      summary: 'Create Current Raffle Logo',
      operationId:
          'create_current_raffle_logo_tombola_raffles__raffle_id__logo_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raffle"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tombola/raffles/${raffleId}/logo');
    final List<PartValue> $parts = <PartValue>[
      PartValueFile<List<int>>('image', image),
    ];
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parts: $parts,
      multipart: true,
      tag: swaggerMetaData,
    );
    return client
        .send<AppTypesStandardResponsesResult, AppTypesStandardResponsesResult>(
          $request,
        );
  }

  @override
  Future<Response<List<int>>> _tombolaRafflesRaffleIdLogoGet({
    required String? raffleId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get the logo of a specific raffle.',
      summary: 'Read Raffle Logo',
      operationId: 'read_raffle_logo_tombola_raffles__raffle_id__logo_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raffle"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tombola/raffles/${raffleId}/logo');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<int>, int>($request);
  }

  @override
  Future<Response<List<PackTicketSimple>>> _tombolaPackTicketsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Return all tickets',
      summary: 'Get Pack Tickets',
      operationId: 'get_pack_tickets_tombola_pack_tickets_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raffle"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tombola/pack_tickets');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<PackTicketSimple>, PackTicketSimple>($request);
  }

  @override
  Future<Response<PackTicketSimple>> _tombolaPackTicketsPost({
    required PackTicketBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a new packticket

**The user must be a member of the raffle\'s group to use this endpoint**''',
      summary: 'Create Packticket',
      operationId: 'create_packticket_tombola_pack_tickets_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raffle"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tombola/pack_tickets');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<PackTicketSimple, PackTicketSimple>($request);
  }

  @override
  Future<Response<void>> _tombolaPackTicketsPackticketIdPatch({
    required String? packticketId,
    required PackTicketEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Edit a packticket

**The user must be a member of the raffle\'s group to use this endpoint**''',
      summary: 'Edit Packticket',
      operationId: 'edit_packticket_tombola_pack_tickets__packticket_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raffle"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tombola/pack_tickets/${packticketId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _tombolaPackTicketsPackticketIdDelete({
    required String? packticketId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Delete a packticket.

**The user must be a member of the raffle\'s group to use this endpoint**''',
      summary: 'Delete Packticket',
      operationId:
          'delete_packticket_tombola_pack_tickets__packticket_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raffle"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tombola/pack_tickets/${packticketId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<PackTicketSimple>>>
  _tombolaRafflesRaffleIdPackTicketsGet({
    required String? raffleId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Return all pack_tickets associated to a raffle',
      summary: 'Get Pack Tickets By Raffle Id',
      operationId:
          'get_pack_tickets_by_raffle_id_tombola_raffles__raffle_id__pack_tickets_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raffle"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tombola/raffles/${raffleId}/pack_tickets');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<PackTicketSimple>, PackTicketSimple>($request);
  }

  @override
  Future<Response<List<TicketSimple>>> _tombolaTicketsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Return all tickets

**The user must be a member of the group admin to use this endpoint**''',
      summary: 'Get Tickets',
      operationId: 'get_tickets_tombola_tickets_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raffle"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tombola/tickets');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<TicketSimple>, TicketSimple>($request);
  }

  @override
  Future<Response<List<AppModulesRaffleSchemasRaffleTicketComplete>>>
  _tombolaTicketsBuyPackIdPost({
    required String? packId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Buy a ticket',
      summary: 'Buy Ticket',
      operationId: 'buy_ticket_tombola_tickets_buy__pack_id__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raffle"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tombola/tickets/buy/${packId}');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<
      List<AppModulesRaffleSchemasRaffleTicketComplete>,
      AppModulesRaffleSchemasRaffleTicketComplete
    >($request);
  }

  @override
  Future<Response<List<AppModulesRaffleSchemasRaffleTicketComplete>>>
  _tombolaUsersUserIdTicketsGet({
    required String? userId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get tickets of a specific user.

**Only admin users can get tickets of another user**''',
      summary: 'Get Tickets By Userid',
      operationId: 'get_tickets_by_userid_tombola_users__user_id__tickets_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raffle"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tombola/users/${userId}/tickets');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<
      List<AppModulesRaffleSchemasRaffleTicketComplete>,
      AppModulesRaffleSchemasRaffleTicketComplete
    >($request);
  }

  @override
  Future<Response<List<AppModulesRaffleSchemasRaffleTicketComplete>>>
  _tombolaRafflesRaffleIdTicketsGet({
    required String? raffleId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get tickets from a specific raffle.

**The user must be a member of the raffle\'s group to use this endpoint''',
      summary: 'Get Tickets By Raffleid',
      operationId:
          'get_tickets_by_raffleid_tombola_raffles__raffle_id__tickets_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raffle"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tombola/raffles/${raffleId}/tickets');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<
      List<AppModulesRaffleSchemasRaffleTicketComplete>,
      AppModulesRaffleSchemasRaffleTicketComplete
    >($request);
  }

  @override
  Future<Response<List<PrizeSimple>>> _tombolaPrizesGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Return all prizes',
      summary: 'Get Prizes',
      operationId: 'get_prizes_tombola_prizes_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raffle"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tombola/prizes');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<PrizeSimple>, PrizeSimple>($request);
  }

  @override
  Future<Response<PrizeSimple>> _tombolaPrizesPost({
    required PrizeBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a new prize

**The user must be a member of the raffle\'s group to use this endpoint''',
      summary: 'Create Prize',
      operationId: 'create_prize_tombola_prizes_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raffle"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tombola/prizes');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<PrizeSimple, PrizeSimple>($request);
  }

  @override
  Future<Response<void>> _tombolaPrizesPrizeIdPatch({
    required String? prizeId,
    required PrizeEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Edit a prize

**The user must be a member of the group raffle\'s to use this endpoint''',
      summary: 'Edit Prize',
      operationId: 'edit_prize_tombola_prizes__prize_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raffle"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tombola/prizes/${prizeId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _tombolaPrizesPrizeIdDelete({
    required String? prizeId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Delete a prize.

**The user must be a member of the group raffle\'s to use this endpoint''',
      summary: 'Delete Prize',
      operationId: 'delete_prize_tombola_prizes__prize_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raffle"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tombola/prizes/${prizeId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<PrizeSimple>>> _tombolaRafflesRaffleIdPrizesGet({
    required String? raffleId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get prizes from a specific raffle.',
      summary: 'Get Prizes By Raffleid',
      operationId:
          'get_prizes_by_raffleid_tombola_raffles__raffle_id__prizes_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raffle"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tombola/raffles/${raffleId}/prizes');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<PrizeSimple>, PrizeSimple>($request);
  }

  @override
  Future<Response<AppTypesStandardResponsesResult>>
  _tombolaPrizesPrizeIdPicturePost({
    required String? prizeId,
    required List<int> image,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Upload a logo for a specific prize.

**The user must be a member of the raffle\'s group to use this endpoint**''',
      summary: 'Create Prize Picture',
      operationId:
          'create_prize_picture_tombola_prizes__prize_id__picture_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raffle"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tombola/prizes/${prizeId}/picture');
    final List<PartValue> $parts = <PartValue>[
      PartValueFile<List<int>>('image', image),
    ];
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parts: $parts,
      multipart: true,
      tag: swaggerMetaData,
    );
    return client
        .send<AppTypesStandardResponsesResult, AppTypesStandardResponsesResult>(
          $request,
        );
  }

  @override
  Future<Response<List<int>>> _tombolaPrizesPrizeIdPictureGet({
    required String? prizeId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get the logo of a specific prize.',
      summary: 'Read Prize Logo',
      operationId: 'read_prize_logo_tombola_prizes__prize_id__picture_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raffle"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tombola/prizes/${prizeId}/picture');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<int>, int>($request);
  }

  @override
  Future<Response<List<AppModulesRaffleSchemasRaffleCashComplete>>>
  _tombolaUsersCashGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get cash from all users.

**The user must be a member of the group admin to use this endpoint''',
      summary: 'Get Users Cash',
      operationId: 'get_users_cash_tombola_users_cash_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raffle"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tombola/users/cash');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<
      List<AppModulesRaffleSchemasRaffleCashComplete>,
      AppModulesRaffleSchemasRaffleCashComplete
    >($request);
  }

  @override
  Future<Response<AppModulesRaffleSchemasRaffleCashComplete>>
  _tombolaUsersUserIdCashGet({
    required String? userId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get cash from a specific user.

**The user must be a member of the group admin to use this endpoint or can only access the endpoint for its own user_id**''',
      summary: 'Get Cash By Id',
      operationId: 'get_cash_by_id_tombola_users__user_id__cash_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raffle"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tombola/users/${userId}/cash');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<
      AppModulesRaffleSchemasRaffleCashComplete,
      AppModulesRaffleSchemasRaffleCashComplete
    >($request);
  }

  @override
  Future<Response<AppModulesRaffleSchemasRaffleCashComplete>>
  _tombolaUsersUserIdCashPost({
    required String? userId,
    required CashEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create cash for a user.

**The user must be a member of the group admin to use this endpoint**''',
      summary: 'Create Cash Of User',
      operationId: 'create_cash_of_user_tombola_users__user_id__cash_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raffle"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tombola/users/${userId}/cash');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<
      AppModulesRaffleSchemasRaffleCashComplete,
      AppModulesRaffleSchemasRaffleCashComplete
    >($request);
  }

  @override
  Future<Response<void>> _tombolaUsersUserIdCashPatch({
    required String? userId,
    required CashEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Edit cash for an user. This will add the balance to the current balance.
A negative value can be provided to remove money from the user.

**The user must be a member of the group admin to use this endpoint**''',
      summary: 'Edit Cash By Id',
      operationId: 'edit_cash_by_id_tombola_users__user_id__cash_patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raffle"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tombola/users/${userId}/cash');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<AppModulesRaffleSchemasRaffleTicketComplete>>>
  _tombolaPrizesPrizeIdDrawPost({
    required String? prizeId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Draw Winner',
      operationId: 'draw_winner_tombola_prizes__prize_id__draw_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raffle"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tombola/prizes/${prizeId}/draw');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<
      List<AppModulesRaffleSchemasRaffleTicketComplete>,
      AppModulesRaffleSchemasRaffleTicketComplete
    >($request);
  }

  @override
  Future<Response<void>> _tombolaRafflesRaffleIdOpenPatch({
    required String? raffleId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Open a raffle

**The user must be a member of the raffle\'s group to use this endpoint**''',
      summary: 'Open Raffle',
      operationId: 'open_raffle_tombola_raffles__raffle_id__open_patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raffle"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tombola/raffles/${raffleId}/open');
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _tombolaRafflesRaffleIdLockPatch({
    required String? raffleId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Lock a raffle

**The user must be a member of the raffle\'s group to use this endpoint**''',
      summary: 'Lock Raffle',
      operationId: 'lock_raffle_tombola_raffles__raffle_id__lock_patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raffle"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tombola/raffles/${raffleId}/lock');
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<Recommendation>>> _recommendationRecommendationsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get recommendations.

**The user must be authenticated to use this endpoint**''',
      summary: 'Get Recommendation',
      operationId: 'get_recommendation_recommendation_recommendations_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Recommendation"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/recommendation/recommendations');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<Recommendation>, Recommendation>($request);
  }

  @override
  Future<Response<Recommendation>> _recommendationRecommendationsPost({
    required RecommendationBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a recommendation.

**This endpoint is only usable by members of the group BDE**''',
      summary: 'Create Recommendation',
      operationId: 'create_recommendation_recommendation_recommendations_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Recommendation"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/recommendation/recommendations');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<Recommendation, Recommendation>($request);
  }

  @override
  Future<Response<void>> _recommendationRecommendationsRecommendationIdPatch({
    required String? recommendationId,
    required RecommendationEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Edit a recommendation.

**This endpoint is only usable by members of the group BDE**''',
      summary: 'Edit Recommendation',
      operationId:
          'edit_recommendation_recommendation_recommendations__recommendation_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Recommendation"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/recommendation/recommendations/${recommendationId}',
    );
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _recommendationRecommendationsRecommendationIdDelete({
    required String? recommendationId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Delete a recommendation.

**This endpoint is only usable by members of the group BDE**''',
      summary: 'Delete Recommendation',
      operationId:
          'delete_recommendation_recommendation_recommendations__recommendation_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Recommendation"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/recommendation/recommendations/${recommendationId}',
    );
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<int>>>
  _recommendationRecommendationsRecommendationIdPictureGet({
    required String? recommendationId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get the image of a recommendation.

**The user must be authenticated to use this endpoint**''',
      summary: 'Read Recommendation Image',
      operationId:
          'read_recommendation_image_recommendation_recommendations__recommendation_id__picture_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Recommendation"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/recommendation/recommendations/${recommendationId}/picture',
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<int>, int>($request);
  }

  @override
  Future<Response<AppTypesStandardResponsesResult>>
  _recommendationRecommendationsRecommendationIdPicturePost({
    required String? recommendationId,
    required List<int> image,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Add an image to a recommendation.

**This endpoint is only usable by members of the group BDE**''',
      summary: 'Create Recommendation Image',
      operationId:
          'create_recommendation_image_recommendation_recommendations__recommendation_id__picture_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Recommendation"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/recommendation/recommendations/${recommendationId}/picture',
    );
    final List<PartValue> $parts = <PartValue>[
      PartValueFile<List<int>>('image', image),
    ];
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parts: $parts,
      multipart: true,
      tag: swaggerMetaData,
    );
    return client
        .send<AppTypesStandardResponsesResult, AppTypesStandardResponsesResult>(
          $request,
        );
  }

  @override
  Future<Response<List<int>>> _phPaperIdPdfGet({
    required String? paperId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Paper Pdf',
      operationId: 'get_paper_pdf_ph__paper_id__pdf_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["ph"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/ph/${paperId}/pdf');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<int>, int>($request);
  }

  @override
  Future<Response<void>> _phPaperIdPdfPost({
    required String? paperId,
    required List<int> pdf,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Create Paper Pdf And Cover',
      operationId: 'create_paper_pdf_and_cover_ph__paper_id__pdf_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["ph"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/ph/${paperId}/pdf');
    final List<PartValue> $parts = <PartValue>[
      PartValueFile<List<int>>('pdf', pdf),
    ];
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parts: $parts,
      multipart: true,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<PaperComplete>>> _phGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Return all editions until now, sorted from the latest to the oldest',
      summary: 'Get Papers',
      operationId: 'get_papers_ph__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["ph"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/ph/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<PaperComplete>, PaperComplete>($request);
  }

  @override
  Future<Response<PaperComplete>> _phPost({
    required PaperBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Create a new paper.',
      summary: 'Create Paper',
      operationId: 'create_paper_ph__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["ph"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/ph/');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<PaperComplete, PaperComplete>($request);
  }

  @override
  Future<Response<List<PaperComplete>>> _phAdminGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Return all editions, sorted from the latest to the oldest',
      summary: 'Get Papers Admin',
      operationId: 'get_papers_admin_ph_admin_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["ph"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/ph/admin');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<PaperComplete>, PaperComplete>($request);
  }

  @override
  Future<Response<dynamic>> _phPaperIdCoverGet({
    required String? paperId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Cover',
      operationId: 'get_cover_ph__paper_id__cover_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["ph"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/ph/${paperId}/cover');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<void>> _phPaperIdPatch({
    required String? paperId,
    required PaperUpdate? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Update Paper',
      operationId: 'update_paper_ph__paper_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["ph"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/ph/${paperId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _phPaperIdDelete({
    required String? paperId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Delete Paper',
      operationId: 'delete_paper_ph__paper_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["ph"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/ph/${paperId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<Loaner>>> _loansLoanersGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get existing loaners.

**This endpoint is only usable by administrators**''',
      summary: 'Read Loaners',
      operationId: 'read_loaners_loans_loaners__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Loans"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/loans/loaners/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<Loaner>, Loaner>($request);
  }

  @override
  Future<Response<Loaner>> _loansLoanersPost({
    required LoanerBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a new loaner.

Each loaner is associated with a `manager_group`. Users belonging to this group are able to manage the loaner items and loans.

**This endpoint is only usable by administrators**''',
      summary: 'Create Loaner',
      operationId: 'create_loaner_loans_loaners__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Loans"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/loans/loaners/');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<Loaner, Loaner>($request);
  }

  @override
  Future<Response<void>> _loansLoanersLoanerIdDelete({
    required String? loanerId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Delete a loaner. All items and loans associated with the loaner will also be deleted from the database.

**This endpoint is only usable by administrators**''',
      summary: 'Delete Loaner',
      operationId: 'delete_loaner_loans_loaners__loaner_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Loans"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/loans/loaners/${loanerId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _loansLoanersLoanerIdPatch({
    required String? loanerId,
    required LoanerUpdate? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Update a loaner, the request should contain a JSON with the fields to change (not necessarily all fields) and their new value.

**This endpoint is only usable by administrators**''',
      summary: 'Update Loaner',
      operationId: 'update_loaner_loans_loaners__loaner_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Loans"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/loans/loaners/${loanerId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<Loan>>> _loansLoanersLoanerIdLoansGet({
    required String? loanerId,
    bool? returned,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Return all loans from a given group.


The query string `returned` can be used to get only return or non returned loans. By default, all loans are returned.


**The user must be a member of the loaner group_manager to use this endpoint**''',
      summary: 'Get Loans By Loaner',
      operationId: 'get_loans_by_loaner_loans_loaners__loaner_id__loans_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Loans"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/loans/loaners/${loanerId}/loans');
    final Map<String, dynamic> $params = <String, dynamic>{
      'returned': returned,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<List<Loan>, Loan>($request);
  }

  @override
  Future<Response<List<Item>>> _loansLoanersLoanerIdItemsGet({
    required String? loanerId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Return all items of a loaner.

**The user must be a member of the loaner group_manager to use this endpoint**''',
      summary: 'Get Items By Loaner',
      operationId: 'get_items_by_loaner_loans_loaners__loaner_id__items_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Loans"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/loans/loaners/${loanerId}/items');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<Item>, Item>($request);
  }

  @override
  Future<Response<Item>> _loansLoanersLoanerIdItemsPost({
    required String? loanerId,
    required ItemBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Create a new item for a loaner. A given loaner can not have more than one item with the same `name`.

**The user must be a member of the loaner group_manager to use this endpoint**''',
      summary: 'Create Items For Loaner',
      operationId:
          'create_items_for_loaner_loans_loaners__loaner_id__items_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Loans"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/loans/loaners/${loanerId}/items');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<Item, Item>($request);
  }

  @override
  Future<Response<void>> _loansLoanersLoanerIdItemsItemIdPatch({
    required String? loanerId,
    required String? itemId,
    required ItemUpdate? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Update a loaner\'s item.

**The user must be a member of the loaner group_manager to use this endpoint**''',
      summary: 'Update Items For Loaner',
      operationId:
          'update_items_for_loaner_loans_loaners__loaner_id__items__item_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Loans"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/loans/loaners/${loanerId}/items/${itemId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _loansLoanersLoanerIdItemsItemIdDelete({
    required String? loanerId,
    required String? itemId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Delete a loaner\'s item.
This will remove the item from all loans but won\'t delete any loan.

**The user must be a member of the loaner group_manager to use this endpoint**''',
      summary: 'Delete Loaner Item',
      operationId:
          'delete_loaner_item_loans_loaners__loaner_id__items__item_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Loans"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/loans/loaners/${loanerId}/items/${itemId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<Loan>>> _loansUsersMeGet({
    bool? returned,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Return all loans from the current user.

The query string `returned` can be used to get only returned or non returned loans. By default, all loans are returned.

**The user must be authenticated to use this endpoint**''',
      summary: 'Get Current User Loans',
      operationId: 'get_current_user_loans_loans_users_me_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Loans"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/loans/users/me');
    final Map<String, dynamic> $params = <String, dynamic>{
      'returned': returned,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<List<Loan>, Loan>($request);
  }

  @override
  Future<Response<List<Loaner>>> _loansUsersMeLoanersGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Return all loaners the current user can manage.

**The user must be authenticated to use this endpoint**''',
      summary: 'Get Current User Loaners',
      operationId: 'get_current_user_loaners_loans_users_me_loaners_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Loans"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/loans/users/me/loaners');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<Loaner>, Loaner>($request);
  }

  @override
  Future<Response<Loan>> _loansPost({
    required LoanCreation? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a new loan in database and add the requested items

**The user must be a member of the loaner group_manager to use this endpoint**''',
      summary: 'Create Loan',
      operationId: 'create_loan_loans__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Loans"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/loans/');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<Loan, Loan>($request);
  }

  @override
  Future<Response<void>> _loansLoanIdPatch({
    required String? loanId,
    required LoanUpdate? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Update a loan and its items.

As the endpoint can update the loan items, it will send back
the new representation of the loan `Loan` including the new items relationships

**The user must be a member of the loaner group_manager to use this endpoint**''',
      summary: 'Update Loan',
      operationId: 'update_loan_loans__loan_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Loans"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/loans/${loanId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _loansLoanIdDelete({
    required String? loanId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Delete a loan
This will remove the loan but won\'t delete any loaner items.

**The user must be a member of the loaner group_manager to use this endpoint**''',
      summary: 'Delete Loan',
      operationId: 'delete_loan_loans__loan_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Loans"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/loans/${loanId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _loansLoanIdReturnPost({
    required String? loanId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Mark a loan as returned. This will update items availability.

**The user must be a member of the loaner group_manager to use this endpoint**''',
      summary: 'Return Loan',
      operationId: 'return_loan_loans__loan_id__return_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Loans"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/loans/${loanId}/return');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _loansLoanIdExtendPost({
    required String? loanId,
    required LoanExtend? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''A new `end` date or an extended `duration` can be provided. If the two are provided, only `end` will be used.

**The user must be a member of the loaner group_manager to use this endpoint**''',
      summary: 'Extend Loan',
      operationId: 'extend_loan_loans__loan_id__extend_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Loans"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/loans/${loanId}/extend');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<FlappyBirdScoreInDB>>> _flappybirdScoresGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Return the leaderboard',
      summary: 'Get Flappybird Score',
      operationId: 'get_flappybird_score_flappybird_scores_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Flappy Bird"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/flappybird/scores');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<FlappyBirdScoreInDB>, FlappyBirdScoreInDB>(
      $request,
    );
  }

  @override
  Future<Response<FlappyBirdScoreInDB>> _flappybirdScoresPost({
    required FlappyBirdScoreBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Create Flappybird Score',
      operationId: 'create_flappybird_score_flappybird_scores_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Flappy Bird"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/flappybird/scores');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<FlappyBirdScoreInDB, FlappyBirdScoreInDB>($request);
  }

  @override
  Future<Response<FlappyBirdScoreCompleteFeedBack>> _flappybirdScoresMeGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Current User Flappybird Personal Best',
      operationId:
          'get_current_user_flappybird_personal_best_flappybird_scores_me_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Flappy Bird"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/flappybird/scores/me');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client
        .send<FlappyBirdScoreCompleteFeedBack, FlappyBirdScoreCompleteFeedBack>(
          $request,
        );
  }

  @override
  Future<Response<void>> _flappybirdScoresTargetedUserIdDelete({
    required String? targetedUserId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Remove Flappybird Score',
      operationId:
          'remove_flappybird_score_flappybird_scores__targeted_user_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Flappy Bird"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/flappybird/scores/${targetedUserId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<Sport>>> _competitionSportsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Sports',
      operationId: 'get_sports_competition_sports_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/sports');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<Sport>, Sport>($request);
  }

  @override
  Future<Response<Sport>> _competitionSportsPost({
    required SportBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Create Sport',
      operationId: 'create_sport_competition_sports_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/sports');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<Sport, Sport>($request);
  }

  @override
  Future<Response<void>> _competitionSportsSportIdPatch({
    required String? sportId,
    required SportEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Edit Sport',
      operationId: 'edit_sport_competition_sports__sport_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/sports/${sportId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _competitionSportsSportIdDelete({
    required String? sportId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Delete Sport',
      operationId: 'delete_sport_competition_sports__sport_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/sports/${sportId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<CompetitionEdition>>> _competitionEditionsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Editions',
      operationId: 'get_editions_competition_editions_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/editions');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<CompetitionEdition>, CompetitionEdition>($request);
  }

  @override
  Future<Response<CompetitionEdition>> _competitionEditionsPost({
    required CompetitionEditionBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Create Edition',
      operationId: 'create_edition_competition_editions_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/editions');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<CompetitionEdition, CompetitionEdition>($request);
  }

  @override
  Future<Response<dynamic>> _competitionEditionsActiveGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get the currently active competition edition.
Returns None if no edition is active.''',
      summary: 'Get Active Edition',
      operationId: 'get_active_edition_competition_editions_active_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/editions/active');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<void>> _competitionEditionsEditionIdActivatePost({
    required String? editionId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Activate a competition edition.
If another edition is already active, it will be deactivated.''',
      summary: 'Activate Edition',
      operationId:
          'activate_edition_competition_editions__edition_id__activate_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/editions/${editionId}/activate');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _competitionEditionsEditionIdInscriptionPost({
    required String? editionId,
    required bool? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Enable inscription for a competition edition.
The edition must already be active.''',
      summary: 'Enable Inscription',
      operationId:
          'enable_inscription_competition_editions__edition_id__inscription_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/competition/editions/${editionId}/inscription',
    );
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _competitionEditionsEditionIdPatch({
    required String? editionId,
    required CompetitionEditionEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Edit Edition',
      operationId: 'edit_edition_competition_editions__edition_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/editions/${editionId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<CompetitionUser>>> _competitionUsersGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get all competition users for the current edition.',
      summary: 'Get Competition Users',
      operationId: 'get_competition_users_competition_users_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/users');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<CompetitionUser>, CompetitionUser>($request);
  }

  @override
  Future<Response<CompetitionUserSimple>> _competitionUsersPost({
    required CompetitionUserBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a competition user for the current edition.
The user must exist in the core users database.''',
      summary: 'Create Competition User',
      operationId: 'create_competition_user_competition_users_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/users');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<CompetitionUserSimple, CompetitionUserSimple>($request);
  }

  @override
  Future<Response<List<CompetitionUser>>> _competitionUsersSchoolsSchoolIdGet({
    required String? schoolId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Get all competition users for the current edition by school.',
      summary: 'Get Competition Users By School',
      operationId:
          'get_competition_users_by_school_competition_users_schools__school_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/users/schools/${schoolId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<CompetitionUser>, CompetitionUser>($request);
  }

  @override
  Future<Response<CompetitionUser>> _competitionUsersMeGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get the competition user for the current edition.
This is the user making the request.''',
      summary: 'Get Current User Competition',
      operationId: 'get_current_user_competition_competition_users_me_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/users/me');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<CompetitionUser, CompetitionUser>($request);
  }

  @override
  Future<Response<void>> _competitionUsersMePatch({
    required CompetitionUserEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Edit the current user\'s competition user for the current edition.
The user must exist in the core users database.''',
      summary: 'Edit Current User Competition',
      operationId: 'edit_current_user_competition_competition_users_me_patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/users/me');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<CompetitionUser>> _competitionUsersUserIdGet({
    required String? userId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Get a competition user by their user ID for the current edition.',
      summary: 'Get Competition User',
      operationId: 'get_competition_user_competition_users__user_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/users/${userId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<CompetitionUser, CompetitionUser>($request);
  }

  @override
  Future<Response<void>> _competitionUsersUserIdPatch({
    required String? userId,
    required CompetitionUserEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Edit a competition user for the current edition.
The user must exist in the core users database.''',
      summary: 'Edit Competition User',
      operationId: 'edit_competition_user_competition_users__user_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/users/${userId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _competitionUsersUserIdDelete({
    required String? userId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Delete Competition User',
      operationId: 'delete_competition_user_competition_users__user_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/users/${userId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _competitionUsersUserIdValidatePatch({
    required String? userId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Validate Competition User',
      operationId:
          'validate_competition_user_competition_users__user_id__validate_patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/users/${userId}/validate');
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _competitionUsersUserIdInvalidatePatch({
    required String? userId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Invalidate Competition User',
      operationId:
          'invalidate_competition_user_competition_users__user_id__invalidate_patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/users/${userId}/invalidate');
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<UserGroupMembershipComplete>>>
  _competitionGroupsGroupGet({
    required String? group,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Get all users in a specific competition group for the current edition.',
      summary: 'Get Group Members',
      operationId: 'get_group_members_competition_groups__group__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/groups/${group}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client
        .send<List<UserGroupMembershipComplete>, UserGroupMembershipComplete>(
          $request,
        );
  }

  @override
  Future<Response<List<UserGroupMembership>>> _competitionUsersMeGroupsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Get all groups the current user is a member of in the current edition.
This is the user making the request.''',
      summary: 'Get Current User Groups',
      operationId: 'get_current_user_groups_competition_users_me_groups_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/users/me/groups');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<UserGroupMembership>, UserGroupMembership>(
      $request,
    );
  }

  @override
  Future<Response<List<UserGroupMembership>>> _competitionUsersUserIdGroupsGet({
    required String? userId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Get all groups a user is a member of in the current edition.',
      summary: 'Get User Groups',
      operationId: 'get_user_groups_competition_users__user_id__groups_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/users/${userId}/groups');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<UserGroupMembership>, UserGroupMembership>(
      $request,
    );
  }

  @override
  Future<Response<UserGroupMembership>> _competitionGroupsGroupUsersUserIdPost({
    required String? group,
    required String? userId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Add User To Group',
      operationId:
          'add_user_to_group_competition_groups__group__users__user_id__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/groups/${group}/users/${userId}');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<UserGroupMembership, UserGroupMembership>($request);
  }

  @override
  Future<Response<void>> _competitionGroupsGroupUsersUserIdDelete({
    required String? group,
    required String? userId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Remove User From Group',
      operationId:
          'remove_user_from_group_competition_groups__group__users__user_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/groups/${group}/users/${userId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<SchoolExtension>>> _competitionSchoolsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Schools',
      operationId: 'get_schools_competition_schools_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/schools');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<SchoolExtension>, SchoolExtension>($request);
  }

  @override
  Future<Response<SchoolExtensionBase>> _competitionSchoolsPost({
    required SchoolExtensionBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Create School Extension',
      operationId: 'create_school_extension_competition_schools_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/schools');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<SchoolExtensionBase, SchoolExtensionBase>($request);
  }

  @override
  Future<Response<SchoolExtension>> _competitionSchoolsSchoolIdGet({
    required String? schoolId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get School',
      operationId: 'get_school_competition_schools__school_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/schools/${schoolId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<SchoolExtension, SchoolExtension>($request);
  }

  @override
  Future<Response<void>> _competitionSchoolsSchoolIdPatch({
    required String? schoolId,
    required SchoolExtensionEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Edit School Extension',
      operationId:
          'edit_school_extension_competition_schools__school_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/schools/${schoolId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _competitionSchoolsSchoolIdDelete({
    required String? schoolId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Delete School Extension',
      operationId:
          'delete_school_extension_competition_schools__school_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/schools/${schoolId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<SchoolGeneralQuota>>
  _competitionSchoolsSchoolIdGeneralQuotaGet({
    required String? schoolId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get School General Quota',
      operationId:
          'get_school_general_quota_competition_schools__school_id__general_quota_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/competition/schools/${schoolId}/general-quota',
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<SchoolGeneralQuota, SchoolGeneralQuota>($request);
  }

  @override
  Future<Response<SchoolGeneralQuota>>
  _competitionSchoolsSchoolIdGeneralQuotaPost({
    required String? schoolId,
    required SchoolGeneralQuotaBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Create School General Quota',
      operationId:
          'create_school_general_quota_competition_schools__school_id__general_quota_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/competition/schools/${schoolId}/general-quota',
    );
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<SchoolGeneralQuota, SchoolGeneralQuota>($request);
  }

  @override
  Future<Response<void>> _competitionSchoolsSchoolIdGeneralQuotaPatch({
    required String? schoolId,
    required SchoolGeneralQuotaBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Edit School General Quota',
      operationId:
          'edit_school_general_quota_competition_schools__school_id__general_quota_patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/competition/schools/${schoolId}/general-quota',
    );
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<SchoolSportQuota>>> _competitionSportsSportIdQuotasGet({
    required String? sportId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Quotas For Sport',
      operationId:
          'get_quotas_for_sport_competition_sports__sport_id__quotas_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/sports/${sportId}/quotas');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<SchoolSportQuota>, SchoolSportQuota>($request);
  }

  @override
  Future<Response<List<SchoolSportQuota>>>
  _competitionSchoolsSchoolIdSportsQuotasGet({
    required String? schoolId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Quotas For School',
      operationId:
          'get_quotas_for_school_competition_schools__school_id__sports_quotas_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/competition/schools/${schoolId}/sports-quotas',
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<SchoolSportQuota>, SchoolSportQuota>($request);
  }

  @override
  Future<Response<void>> _competitionSchoolsSchoolIdSportsSportIdQuotasPost({
    required String? schoolId,
    required String? sportId,
    required SportQuotaInfo? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Create Sport Quota',
      operationId:
          'create_sport_quota_competition_schools__school_id__sports__sport_id__quotas_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/competition/schools/${schoolId}/sports/${sportId}/quotas',
    );
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _competitionSchoolsSchoolIdSportsSportIdQuotasPatch({
    required String? schoolId,
    required String? sportId,
    required SchoolSportQuotaEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Edit Sport Quota',
      operationId:
          'edit_sport_quota_competition_schools__school_id__sports__sport_id__quotas_patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/competition/schools/${schoolId}/sports/${sportId}/quotas',
    );
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _competitionSchoolsSchoolIdSportsSportIdQuotasDelete({
    required String? schoolId,
    required String? sportId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Delete Sport Quota',
      operationId:
          'delete_sport_quota_competition_schools__school_id__sports__sport_id__quotas_delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/competition/schools/${schoolId}/sports/${sportId}/quotas',
    );
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<SchoolProductQuota>>>
  _competitionSchoolsSchoolIdProductQuotasGet({
    required String? schoolId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Product Quotas For School',
      operationId:
          'get_product_quotas_for_school_competition_schools__school_id__product_quotas_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/competition/schools/${schoolId}/product-quotas',
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<SchoolProductQuota>, SchoolProductQuota>($request);
  }

  @override
  Future<Response<SchoolProductQuota>>
  _competitionSchoolsSchoolIdProductQuotasPost({
    required String? schoolId,
    required SchoolProductQuotaBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Create Product Quota',
      operationId:
          'create_product_quota_competition_schools__school_id__product_quotas_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/competition/schools/${schoolId}/product-quotas',
    );
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<SchoolProductQuota, SchoolProductQuota>($request);
  }

  @override
  Future<Response<List<SchoolProductQuota>>>
  _competitionProductsProductIdSchoolsQuotasGet({
    required String? productId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Product Quotas For Product',
      operationId:
          'get_product_quotas_for_product_competition_products__product_id__schools_quotas_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/competition/products/${productId}/schools-quotas',
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<SchoolProductQuota>, SchoolProductQuota>($request);
  }

  @override
  Future<Response<void>>
  _competitionSchoolsSchoolIdProductQuotasProductIdPatch({
    required String? schoolId,
    required String? productId,
    required SchoolProductQuotaEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Edit Product Quota',
      operationId:
          'edit_product_quota_competition_schools__school_id__product_quotas__product_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/competition/schools/${schoolId}/product-quotas/${productId}',
    );
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>>
  _competitionSchoolsSchoolIdProductQuotasProductIdDelete({
    required String? schoolId,
    required String? productId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Delete Product Quota',
      operationId:
          'delete_product_quota_competition_schools__school_id__product_quotas__product_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/competition/schools/${schoolId}/product-quotas/${productId}',
    );
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<TeamComplete>>> _competitionTeamsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Teams',
      operationId: 'get_teams_competition_teams_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/teams');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<TeamComplete>, TeamComplete>($request);
  }

  @override
  Future<Response<Team>> _competitionTeamsPost({
    required TeamInfo? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Create Team',
      operationId: 'create_team_competition_teams_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/teams');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<Team, Team>($request);
  }

  @override
  Future<Response<TeamComplete>> _competitionTeamsMeGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Current User Team As Captain',
      operationId: 'get_current_user_team_as_captain_competition_teams_me_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/teams/me');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<TeamComplete, TeamComplete>($request);
  }

  @override
  Future<Response<List<TeamComplete>>> _competitionTeamsSportsSportIdGet({
    required String? sportId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Teams For Sport',
      operationId:
          'get_teams_for_sport_competition_teams_sports__sport_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/teams/sports/${sportId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<TeamComplete>, TeamComplete>($request);
  }

  @override
  Future<Response<List<TeamComplete>>> _competitionTeamsSchoolsSchoolIdGet({
    required String? schoolId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Teams For School',
      operationId:
          'get_teams_for_school_competition_teams_schools__school_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/teams/schools/${schoolId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<TeamComplete>, TeamComplete>($request);
  }

  @override
  Future<Response<List<TeamComplete>>>
  _competitionTeamsSportsSportIdSchoolsSchoolIdGet({
    required String? schoolId,
    required String? sportId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Sport Teams For School And Sport',
      operationId:
          'get_sport_teams_for_school_and_sport_competition_teams_sports__sport_id__schools__school_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/competition/teams/sports/${sportId}/schools/${schoolId}',
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<TeamComplete>, TeamComplete>($request);
  }

  @override
  Future<Response<void>> _competitionTeamsTeamIdPatch({
    required String? teamId,
    required TeamEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Edit Team',
      operationId: 'edit_team_competition_teams__team_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/teams/${teamId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _competitionTeamsTeamIdDelete({
    required String? teamId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Delete Team',
      operationId: 'delete_team_competition_teams__team_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/teams/${teamId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<ParticipantComplete>> _competitionParticipantsMeGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Current User Participant',
      operationId:
          'get_current_user_participant_competition_participants_me_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/participants/me');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<ParticipantComplete, ParticipantComplete>($request);
  }

  @override
  Future<Response<List<ParticipantComplete>>>
  _competitionParticipantsSportsSportIdGet({
    required String? sportId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Participants For Sport',
      operationId:
          'get_participants_for_sport_competition_participants_sports__sport_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/participants/sports/${sportId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<ParticipantComplete>, ParticipantComplete>(
      $request,
    );
  }

  @override
  Future<Response<List<ParticipantComplete>>>
  _competitionParticipantsSchoolsSchoolIdGet({
    required String? schoolId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Participants For School',
      operationId:
          'get_participants_for_school_competition_participants_schools__school_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/participants/schools/${schoolId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<ParticipantComplete>, ParticipantComplete>(
      $request,
    );
  }

  @override
  Future<Response<List<int>>>
  _competitionParticipantsUsersUserIdCertificateGet({
    required String? userId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Download Participant Certificate',
      operationId:
          'download_participant_certificate_competition_participants_users__user_id__certificate_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/competition/participants/users/${userId}/certificate',
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<int>, int>($request);
  }

  @override
  Future<Response<Participant>> _competitionSportsSportIdParticipatePost({
    required String? sportId,
    required ParticipantInfo? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Join Sport',
      operationId: 'join_sport_competition_sports__sport_id__participate_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/sports/${sportId}/participate');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<Participant, Participant>($request);
  }

  @override
  Future<Response<void>> _competitionParticipantsSportsSportIdCertificatePost({
    required String? sportId,
    required List<int> certificate,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Upload Participant Certificate',
      operationId:
          'upload_participant_certificate_competition_participants_sports__sport_id__certificate_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/competition/participants/sports/${sportId}/certificate',
    );
    final List<PartValue> $parts = <PartValue>[
      PartValueFile<List<int>>('certificate', certificate),
    ];
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parts: $parts,
      multipart: true,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>>
  _competitionParticipantsSportsSportIdCertificateDelete({
    required String? sportId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Delete Participant Certificate File',
      operationId:
          'delete_participant_certificate_file_competition_participants_sports__sport_id__certificate_delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/competition/participants/sports/${sportId}/certificate',
    );
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>>
  _competitionParticipantsSportsSportIdUsersUserIdLicensePatch({
    required String? sportId,
    required String? userId,
    required bool? isLicenseValid,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Mark Participant License As Valid',
      operationId:
          'mark_participant_license_as_valid_competition_participants_sports__sport_id__users__user_id__license_patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/competition/participants/sports/${sportId}/users/${userId}/license',
    );
    final Map<String, dynamic> $params = <String, dynamic>{
      'is_license_valid': isLicenseValid,
    };
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _competitionSportsSportIdWithdrawDelete({
    required String? sportId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Withdraw From Sport',
      operationId:
          'withdraw_from_sport_competition_sports__sport_id__withdraw_delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/sports/${sportId}/withdraw');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _competitionParticipantsUserIdSportsSportIdDelete({
    required String? userId,
    required String? sportId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Delete Participant',
      operationId:
          'delete_participant_competition_participants__user_id__sports__sport_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/competition/participants/${userId}/sports/${sportId}',
    );
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<Location>>> _competitionLocationsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get All Locations',
      operationId: 'get_all_locations_competition_locations_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/locations');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<Location>, Location>($request);
  }

  @override
  Future<Response<Location>> _competitionLocationsPost({
    required LocationBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Create Location',
      operationId: 'create_location_competition_locations_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/locations');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<Location, Location>($request);
  }

  @override
  Future<Response<LocationComplete>> _competitionLocationsLocationIdGet({
    required String? locationId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Location By Id',
      operationId: 'get_location_by_id_competition_locations__location_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/locations/${locationId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<LocationComplete, LocationComplete>($request);
  }

  @override
  Future<Response<void>> _competitionLocationsLocationIdPatch({
    required String? locationId,
    required LocationEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Edit Location',
      operationId: 'edit_location_competition_locations__location_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/locations/${locationId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _competitionLocationsLocationIdDelete({
    required String? locationId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Delete Location',
      operationId: 'delete_location_competition_locations__location_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/locations/${locationId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<MatchComplete>>> _competitionMatchesGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get All Matches For Edition',
      operationId: 'get_all_matches_for_edition_competition_matches_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/matches');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<MatchComplete>, MatchComplete>($request);
  }

  @override
  Future<Response<List<MatchComplete>>> _competitionMatchesSportsSportIdGet({
    required String? sportId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Matches For Sport And Edition',
      operationId:
          'get_matches_for_sport_and_edition_competition_matches_sports__sport_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/matches/sports/${sportId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<MatchComplete>, MatchComplete>($request);
  }

  @override
  Future<Response<Match>> _competitionMatchesSportsSportIdPost({
    required String? sportId,
    required MatchBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Create Match',
      operationId: 'create_match_competition_matches_sports__sport_id__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/matches/sports/${sportId}');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<Match, Match>($request);
  }

  @override
  Future<Response<List<MatchComplete>>> _competitionMatchesSchoolsSchoolIdGet({
    required String? schoolId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Matches For School Sport And Edition',
      operationId:
          'get_matches_for_school_sport_and_edition_competition_matches_schools__school_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/matches/schools/${schoolId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<MatchComplete>, MatchComplete>($request);
  }

  @override
  Future<Response<void>> _competitionMatchesMatchIdPatch({
    required String? matchId,
    required MatchEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Edit Match',
      operationId: 'edit_match_competition_matches__match_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/matches/${matchId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _competitionMatchesMatchIdDelete({
    required String? matchId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Delete Match',
      operationId: 'delete_match_competition_matches__match_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/matches/${matchId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<SchoolResult>>> _competitionPodiumsGlobalGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get the global podiums for the current edition.',
      summary: 'Get Global Podiums',
      operationId: 'get_global_podiums_competition_podiums_global_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/podiums/global');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<SchoolResult>, SchoolResult>($request);
  }

  @override
  Future<Response<List<TeamSportResultComplete>>>
  _competitionPodiumsSportsSportIdGet({
    required String? sportId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Get the podiums for a specific sport in the current edition.',
      summary: 'Get Sport Podiums',
      operationId:
          'get_sport_podiums_competition_podiums_sports__sport_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/podiums/sports/${sportId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<TeamSportResultComplete>, TeamSportResultComplete>(
      $request,
    );
  }

  @override
  Future<Response<List<TeamSportResult>>> _competitionPodiumsSportsSportIdPost({
    required String? sportId,
    required SportPodiumRankings? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Create or update the podium for a specific sport in the current edition.',
      summary: 'Create Sport Podium',
      operationId:
          'create_sport_podium_competition_podiums_sports__sport_id__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/podiums/sports/${sportId}');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<List<TeamSportResult>, TeamSportResult>($request);
  }

  @override
  Future<Response<void>> _competitionPodiumsSportsSportIdDelete({
    required String? sportId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Delete the podium for a specific sport in the current edition.',
      summary: 'Delete Sport Podium',
      operationId:
          'delete_sport_podium_competition_podiums_sports__sport_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/podiums/sports/${sportId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<SchoolResult>>> _competitionPodiumsPompomsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get the pompoms podiums in the current edition.',
      summary: 'Get Pompom Podiums',
      operationId: 'get_pompom_podiums_competition_podiums_pompoms_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/podiums/pompoms');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<SchoolResult>, SchoolResult>($request);
  }

  @override
  Future<Response<List<SchoolResult>>> _competitionPodiumsPompomsPost({
    required List<SchoolResult>? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Create or update the pompoms podium in the current edition.',
      summary: 'Create Pompom Podium',
      operationId: 'create_pompom_podium_competition_podiums_pompoms_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/podiums/pompoms');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<List<SchoolResult>, SchoolResult>($request);
  }

  @override
  Future<Response<void>> _competitionPodiumsPompomsDelete({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Delete the pompoms podium in the current edition.',
      summary: 'Delete Pompom Podium',
      operationId: 'delete_pompom_podium_competition_podiums_pompoms_delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/podiums/pompoms');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<TeamSportResultComplete>>>
  _competitionPodiumsSchoolsSchoolIdGet({
    required String? schoolId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Get the podiums for a specific school in the current edition.',
      summary: 'Get School Podiums',
      operationId:
          'get_school_podiums_competition_podiums_schools__school_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/podiums/schools/${schoolId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<TeamSportResultComplete>, TeamSportResultComplete>(
      $request,
    );
  }

  @override
  Future<
    Response<
      List<AppModulesSportCompetitionSchemasSportCompetitionProductComplete>
    >
  >
  _competitionProductsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get all products.',
      summary: 'Get All Products',
      operationId: 'get_all_products_competition_products_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/products');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<
      List<AppModulesSportCompetitionSchemasSportCompetitionProductComplete>,
      AppModulesSportCompetitionSchemasSportCompetitionProductComplete
    >($request);
  }

  @override
  Future<
    Response<AppModulesSportCompetitionSchemasSportCompetitionProductComplete>
  >
  _competitionProductsPost({
    required AppModulesSportCompetitionSchemasSportCompetitionProductBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Create a product.',
      summary: 'Create Product',
      operationId: 'create_product_competition_products_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/products');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<
      AppModulesSportCompetitionSchemasSportCompetitionProductComplete,
      AppModulesSportCompetitionSchemasSportCompetitionProductComplete
    >($request);
  }

  @override
  Future<Response<void>> _competitionProductsProductIdPatch({
    required String? productId,
    required AppModulesSportCompetitionSchemasSportCompetitionProductEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Edit a product.

**User must be a competition admin to use this endpoint**''',
      summary: 'Update Product',
      operationId: 'update_product_competition_products__product_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/products/${productId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _competitionProductsProductIdDelete({
    required String? productId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Delete a product.

**User must be a competition admin to use this endpoint**''',
      summary: 'Delete Product',
      operationId: 'delete_product_competition_products__product_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/products/${productId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<
    Response<
      List<
        AppModulesSportCompetitionSchemasSportCompetitionProductVariantComplete
      >
    >
  >
  _competitionProductsAvailableGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Get all available product variants of the current edition for this user.',
      summary: 'Get Available Product Variants',
      operationId:
          'get_available_product_variants_competition_products_available_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/products/available');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<
      List<
        AppModulesSportCompetitionSchemasSportCompetitionProductVariantComplete
      >,
      AppModulesSportCompetitionSchemasSportCompetitionProductVariantComplete
    >($request);
  }

  @override
  Future<Response<ProductVariant>> _competitionProductsProductIdVariantsPost({
    required String? productId,
    required AppModulesSportCompetitionSchemasSportCompetitionProductVariantBase?
    body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a product variant.

**User must be a competition admin to use this endpoint**''',
      summary: 'Create Product Variant',
      operationId:
          'create_product_variant_competition_products__product_id__variants_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/products/${productId}/variants');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<ProductVariant, ProductVariant>($request);
  }

  @override
  Future<Response<void>> _competitionProductsVariantsVariantIdPatch({
    required String? variantId,
    required AppModulesSportCompetitionSchemasSportCompetitionProductVariantEdit?
    body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Edit a product variant.

**User must be a competition admin to use this endpoint**''',
      summary: 'Update Product Variant',
      operationId:
          'update_product_variant_competition_products_variants__variant_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/products/variants/${variantId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _competitionProductsVariantsVariantIdDelete({
    required String? variantId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Delete a product variant.

**User must be a competition admin to use this endpoint**''',
      summary: 'Delete Product Variant',
      operationId:
          'delete_product_variant_competition_products_variants__variant_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/products/variants/${variantId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<Object>> _competitionPurchasesSchoolsSchoolIdGet({
    required String? schoolId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get a school\'s purchases.

**User must be competition admin to use this endpoint**''',
      summary: 'Get Purchases By School Id',
      operationId:
          'get_purchases_by_school_id_competition_purchases_schools__school_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/purchases/schools/${schoolId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<Object, Object>($request);
  }

  @override
  Future<Response<List<Purchase>>> _competitionPurchasesUsersUserIdGet({
    required String? userId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get a user\'s purchases.

**User must be competition admin to use this endpoint**''',
      summary: 'Get Purchases By User Id',
      operationId:
          'get_purchases_by_user_id_competition_purchases_users__user_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/purchases/users/${userId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<Purchase>, Purchase>($request);
  }

  @override
  Future<Response<Purchase>> _competitionPurchasesUsersUserIdPost({
    required String? userId,
    required AppModulesSportCompetitionSchemasSportCompetitionPurchaseBase?
    body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a user\'s purchase.

**User must be competition admin to use this endpoint**''',
      summary: 'Create User Purchase',
      operationId:
          'create_user_purchase_competition_purchases_users__user_id__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/purchases/users/${userId}');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<Purchase, Purchase>($request);
  }

  @override
  Future<Response<List<Purchase>>> _competitionPurchasesMeGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get My Purchases',
      operationId: 'get_my_purchases_competition_purchases_me_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/purchases/me');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<Purchase>, Purchase>($request);
  }

  @override
  Future<Response<Purchase>> _competitionPurchasesMePost({
    required AppModulesSportCompetitionSchemasSportCompetitionPurchaseBase?
    body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a purchase.

**User must create a purchase for themself**''',
      summary: 'Create Purchase',
      operationId: 'create_purchase_competition_purchases_me_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/purchases/me');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<Purchase, Purchase>($request);
  }

  @override
  Future<Response<void>>
  _competitionPurchasesUsersUserIdVariantsVariantIdPatch({
    required String? userId,
    required String? variantId,
    required PurchaseEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Edit a user\'s purchase.

**User must be competition admin to use this endpoint**''',
      summary: 'Update User Purchase',
      operationId:
          'update_user_purchase_competition_purchases_users__user_id__variants__variant_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/competition/purchases/users/${userId}/variants/${variantId}',
    );
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _competitionPurchasesProductVariantIdDelete({
    required String? productVariantId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Delete a purchase.

**User must delete their own purchase**''',
      summary: 'Delete Purchase',
      operationId:
          'delete_purchase_competition_purchases__product_variant_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/purchases/${productVariantId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>>
  _competitionUsersUserIdPurchasesProductVariantIdDelete({
    required String? userId,
    required String? productVariantId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Delete a user\'s purchase.

**User must be competition admin to use this endpoint**''',
      summary: 'Delete User Purchase',
      operationId:
          'delete_user_purchase_competition_users__user_id__purchases__product_variant_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/competition/users/${userId}/purchases/${productVariantId}',
    );
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<Object>> _competitionPaymentsSchoolsSchoolIdGet({
    required String? schoolId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get a school\'s users payments.

**User must be competition admin to use this endpoint**''',
      summary: 'Get Users Payments By School Id',
      operationId:
          'get_users_payments_by_school_id_competition_payments_schools__school_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/payments/schools/${schoolId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<Object, Object>($request);
  }

  @override
  Future<
    Response<
      List<AppModulesSportCompetitionSchemasSportCompetitionPaymentComplete>
    >
  >
  _competitionUsersUserIdPaymentsGet({
    required String? userId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get a user\'s payments.

**User must get his own payments or be competition admin to use this endpoint**''',
      summary: 'Get Payments By User Id',
      operationId:
          'get_payments_by_user_id_competition_users__user_id__payments_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/users/${userId}/payments');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<
      List<AppModulesSportCompetitionSchemasSportCompetitionPaymentComplete>,
      AppModulesSportCompetitionSchemasSportCompetitionPaymentComplete
    >($request);
  }

  @override
  Future<
    Response<AppModulesSportCompetitionSchemasSportCompetitionPaymentComplete>
  >
  _competitionUsersUserIdPaymentsPost({
    required String? userId,
    required AppModulesSportCompetitionSchemasSportCompetitionPaymentBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a payment.

**User must be competition admin to use this endpoint**''',
      summary: 'Create Payment',
      operationId: 'create_payment_competition_users__user_id__payments_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/users/${userId}/payments');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<
      AppModulesSportCompetitionSchemasSportCompetitionPaymentComplete,
      AppModulesSportCompetitionSchemasSportCompetitionPaymentComplete
    >($request);
  }

  @override
  Future<Response<void>> _competitionUsersUserIdPaymentsPaymentIdDelete({
    required String? userId,
    required String? paymentId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Remove a payment.

**User must be competition admin to use this endpoint**''',
      summary: 'Delete Payment',
      operationId:
          'delete_payment_competition_users__user_id__payments__payment_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/competition/users/${userId}/payments/${paymentId}',
    );
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<PaymentUrl>> _competitionPayPost({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get payment url',
      summary: 'Get Payment Url',
      operationId: 'get_payment_url_competition_pay_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/pay');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<PaymentUrl, PaymentUrl>($request);
  }

  @override
  Future<Response<List<VolunteerShiftComplete>>>
  _competitionVolunteersShiftsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get all volunteer shifts.',
      summary: 'Get All Volunteer Shifts',
      operationId: 'get_all_volunteer_shifts_competition_volunteers_shifts_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/volunteers/shifts');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<VolunteerShiftComplete>, VolunteerShiftComplete>(
      $request,
    );
  }

  @override
  Future<Response<VolunteerShift>> _competitionVolunteersShiftsPost({
    required VolunteerShiftBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Create a volunteer shift.',
      summary: 'Create Volunteer Shift',
      operationId: 'create_volunteer_shift_competition_volunteers_shifts_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/volunteers/shifts');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<VolunteerShift, VolunteerShift>($request);
  }

  @override
  Future<Response<void>> _competitionVolunteersShiftsShiftIdPatch({
    required String? shiftId,
    required VolunteerShiftEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Edit a volunteer shift.

**User must be a competition admin to use this endpoint**''',
      summary: 'Update Volunteer Shift',
      operationId:
          'update_volunteer_shift_competition_volunteers_shifts__shift_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/volunteers/shifts/${shiftId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _competitionVolunteersShiftsShiftIdDelete({
    required String? shiftId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Delete a volunteer shift.

**User must be a competition admin to use this endpoint**''',
      summary: 'Delete Volunteer Shift',
      operationId:
          'delete_volunteer_shift_competition_volunteers_shifts__shift_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/volunteers/shifts/${shiftId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<VolunteerRegistrationComplete>>>
  _competitionVolunteersMeGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get my volunteer registrations.',
      summary: 'Get My Volunteer Registrations',
      operationId:
          'get_my_volunteer_registrations_competition_volunteers_me_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/volunteers/me');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<
      List<VolunteerRegistrationComplete>,
      VolunteerRegistrationComplete
    >($request);
  }

  @override
  Future<Response<void>> _competitionVolunteersShiftsShiftIdRegisterPost({
    required String? shiftId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Register to a volunteer shift.',
      summary: 'Register To Volunteer Shift',
      operationId:
          'register_to_volunteer_shift_competition_volunteers_shifts__shift_id__register_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/competition/volunteers/shifts/${shiftId}/register',
    );
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<int>>> _competitionDataExportUsersGet({
    List<Object?>? includedFields,
    bool? excludeNonValidated,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Export competition users data for the current edition as a CSV file.',
      summary: 'Export Competition Users Data',
      operationId:
          'export_competition_users_data_competition_data_export_users_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/competition/data-export/users');
    final Map<String, dynamic> $params = <String, dynamic>{
      'included_fields': includedFields,
      'exclude_non_validated': excludeNonValidated,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<List<int>, int>($request);
  }

  @override
  Future<Response<List<int>>> _competitionDataExportSchoolsSchoolIdUsersGet({
    required String? schoolId,
    List<Object?>? includedFields,
    bool? excludeNonValidated,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Export competition users data for the current edition as a CSV file.',
      summary: 'Export School Competition Users Data',
      operationId:
          'export_school_competition_users_data_competition_data_export_schools__school_id__users_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/competition/data-export/schools/${schoolId}/users',
    );
    final Map<String, dynamic> $params = <String, dynamic>{
      'included_fields': includedFields,
      'exclude_non_validated': excludeNonValidated,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<List<int>, int>($request);
  }

  @override
  Future<Response<List<int>>> _competitionDataExportParticipantsCaptainsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Export participants captains data for the current edition as an Excel file.',
      summary: 'Export Participants Captains Data',
      operationId:
          'export_participants_captains_data_competition_data_export_participants_captains_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/competition/data-export/participants/captains',
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<int>, int>($request);
  }

  @override
  Future<Response<List<int>>> _competitionDataExportSchoolsSchoolIdQuotasGet({
    required String? schoolId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Export school quotas data for the current edition as an Excel file.',
      summary: 'Export School Quotas Data',
      operationId:
          'export_school_quotas_data_competition_data_export_schools__school_id__quotas_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/competition/data-export/schools/${schoolId}/quotas',
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<int>, int>($request);
  }

  @override
  Future<Response<List<int>>> _competitionDataExportSportsSportIdQuotasGet({
    required String? sportId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Export sport quotas data for the current edition as an Excel file.',
      summary: 'Export Sport Quotas Data',
      operationId:
          'export_sport_quotas_data_competition_data_export_sports__sport_id__quotas_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/competition/data-export/sports/${sportId}/quotas',
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<int>, int>($request);
  }

  @override
  Future<Response<List<int>>>
  _competitionDataExportSportsSportIdParticipantsGet({
    required String? sportId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Export sport quotas data for the current edition as an Excel file.',
      summary: 'Export Sport Participants Data',
      operationId:
          'export_sport_participants_data_competition_data_export_sports__sport_id__participants_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Sport Competition"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/competition/data-export/sports/${sportId}/participants',
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<int>, int>($request);
  }

  @override
  Future<Response<List<AdvertComplete>>> _advertAdvertsGet({
    List<String>? advertisers,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Get existing adverts. If advertisers optional parameter is used, search adverts by advertisers

**The user must be authenticated to use this endpoint**''',
      summary: 'Read Adverts',
      operationId: 'read_adverts_advert_adverts_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Advert"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/advert/adverts');
    final Map<String, dynamic> $params = <String, dynamic>{
      'advertisers': advertisers,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<List<AdvertComplete>, AdvertComplete>($request);
  }

  @override
  Future<Response<AdvertComplete>> _advertAdvertsPost({
    required AdvertBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a new advert

**The user must be a member of the advertiser group to use this endpoint**''',
      summary: 'Create Advert',
      operationId: 'create_advert_advert_adverts_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Advert"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/advert/adverts');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<AdvertComplete, AdvertComplete>($request);
  }

  @override
  Future<Response<AdvertComplete>> _advertAdvertsAdvertIdGet({
    required String? advertId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get an advert

**The user must be authenticated to use this endpoint**''',
      summary: 'Read Advert',
      operationId: 'read_advert_advert_adverts__advert_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Advert"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/advert/adverts/${advertId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<AdvertComplete, AdvertComplete>($request);
  }

  @override
  Future<Response<void>> _advertAdvertsAdvertIdPatch({
    required String? advertId,
    required AdvertUpdate? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Edit an advert

**The user must be a member of the advertiser group_manager to use this endpoint**''',
      summary: 'Update Advert',
      operationId: 'update_advert_advert_adverts__advert_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Advert"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/advert/adverts/${advertId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _advertAdvertsAdvertIdDelete({
    required String? advertId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Delete an advert

**The user must be admin or a member of the advertiser group_manager to use this endpoint**''',
      summary: 'Delete Advert',
      operationId: 'delete_advert_advert_adverts__advert_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Advert"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/advert/adverts/${advertId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<int>>> _advertAdvertsAdvertIdPictureGet({
    required String? advertId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get the image of an advert

**The user must be authenticated to use this endpoint**''',
      summary: 'Read Advert Image',
      operationId: 'read_advert_image_advert_adverts__advert_id__picture_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Advert"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/advert/adverts/${advertId}/picture');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<int>, int>($request);
  }

  @override
  Future<Response<void>> _advertAdvertsAdvertIdPicturePost({
    required String? advertId,
    required List<int> image,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Add an image to an advert

**The user must be authenticated to use this endpoint**''',
      summary: 'Create Advert Image',
      operationId:
          'create_advert_image_advert_adverts__advert_id__picture_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Advert"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/advert/adverts/${advertId}/picture');
    final List<PartValue> $parts = <PartValue>[
      PartValueFile<List<int>>('image', image),
    ];
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parts: $parts,
      multipart: true,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<AssociationComplete>>> _phonebookAssociationsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Return all associations from database as a list of AssociationComplete schemas',
      summary: 'Get All Associations',
      operationId: 'get_all_associations_phonebook_associations__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Phonebook"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/phonebook/associations/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<AssociationComplete>, AssociationComplete>(
      $request,
    );
  }

  @override
  Future<Response<AssociationComplete>> _phonebookAssociationsPost({
    required AppModulesPhonebookSchemasPhonebookAssociationBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Create a new Association by giving an AssociationBase scheme',
      summary: 'Create Association',
      operationId: 'create_association_phonebook_associations__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Phonebook"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/phonebook/associations/');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<AssociationComplete, AssociationComplete>($request);
  }

  @override
  Future<Response<RoleTagsReturn>> _phonebookRoletagsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Return all available role tags from RoleTags enum.',
      summary: 'Get All Role Tags',
      operationId: 'get_all_role_tags_phonebook_roletags_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Phonebook"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/phonebook/roletags');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<RoleTagsReturn, RoleTagsReturn>($request);
  }

  @override
  Future<Response<List<AssociationGroupement>>> _phonebookGroupementsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Return all groupements from database as a list of AssociationGroupement schemas',
      summary: 'Get All Groupements',
      operationId: 'get_all_groupements_phonebook_groupements__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Phonebook"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/phonebook/groupements/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<AssociationGroupement>, AssociationGroupement>(
      $request,
    );
  }

  @override
  Future<Response<AssociationGroupement>> _phonebookGroupementsPost({
    required AssociationGroupementBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Create Groupement',
      operationId: 'create_groupement_phonebook_groupements__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Phonebook"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/phonebook/groupements/');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<AssociationGroupement, AssociationGroupement>($request);
  }

  @override
  Future<Response<void>> _phonebookGroupementsGroupementIdPatch({
    required String? groupementId,
    required AssociationGroupementBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Update a groupement',
      summary: 'Update Groupement',
      operationId:
          'update_groupement_phonebook_groupements__groupement_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Phonebook"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/phonebook/groupements/${groupementId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _phonebookGroupementsGroupementIdDelete({
    required String? groupementId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Delete a groupement',
      summary: 'Delete Groupement',
      operationId:
          'delete_groupement_phonebook_groupements__groupement_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Phonebook"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/phonebook/groupements/${groupementId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _phonebookAssociationsAssociationIdPatch({
    required String? associationId,
    required AssociationEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Update an Association',
      summary: 'Update Association',
      operationId:
          'update_association_phonebook_associations__association_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Phonebook"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/phonebook/associations/${associationId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _phonebookAssociationsAssociationIdDelete({
    required String? associationId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Delete an Association

[!] Memberships linked to association_id will be deleted too''',
      summary: 'Delete Association',
      operationId:
          'delete_association_phonebook_associations__association_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Phonebook"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/phonebook/associations/${associationId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _phonebookAssociationsAssociationIdGroupsPatch({
    required String? associationId,
    required AssociationGroupsEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Update the groups associated with an Association',
      summary: 'Update Association Groups',
      operationId:
          'update_association_groups_phonebook_associations__association_id__groups_patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Phonebook"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/phonebook/associations/${associationId}/groups',
    );
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _phonebookAssociationsAssociationIdDeactivatePatch({
    required String? associationId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Deactivate an Association',
      summary: 'Deactivate Association',
      operationId:
          'deactivate_association_phonebook_associations__association_id__deactivate_patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Phonebook"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/phonebook/associations/${associationId}/deactivate',
    );
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<MemberComplete>>>
  _phonebookAssociationsAssociationIdMembersGet({
    required String? associationId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Return the list of MemberComplete of an Association.',
      summary: 'Get Association Members',
      operationId:
          'get_association_members_phonebook_associations__association_id__members__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Phonebook"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/phonebook/associations/${associationId}/members/',
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<MemberComplete>, MemberComplete>($request);
  }

  @override
  Future<Response<List<MemberComplete>>>
  _phonebookAssociationsAssociationIdMembersMandateYearGet({
    required String? associationId,
    required int? mandateYear,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Return the list of MemberComplete of an Association with given mandate_year.',
      summary: 'Get Association Members By Mandate Year',
      operationId:
          'get_association_members_by_mandate_year_phonebook_associations__association_id__members__mandate_year__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Phonebook"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/phonebook/associations/${associationId}/members/${mandateYear}',
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<MemberComplete>, MemberComplete>($request);
  }

  @override
  Future<Response<MemberComplete>> _phonebookMemberUserIdGet({
    required String? userId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Return MemberComplete for given user_id.',
      summary: 'Get Member Details',
      operationId: 'get_member_details_phonebook_member__user_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Phonebook"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/phonebook/member/${userId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<MemberComplete, MemberComplete>($request);
  }

  @override
  Future<Response<MembershipComplete>> _phonebookAssociationsMembershipsPost({
    required AppModulesPhonebookSchemasPhonebookMembershipBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a new Membership.
\'role_tags\' are used to indicate if the members has a main role in the association (president, secretary ...) and \'role_name\' is the display name for this membership''',
      summary: 'Create Membership',
      operationId: 'create_membership_phonebook_associations_memberships_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Phonebook"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/phonebook/associations/memberships');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<MembershipComplete, MembershipComplete>($request);
  }

  @override
  Future<Response<void>> _phonebookAssociationsMembershipsMembershipIdPatch({
    required String? membershipId,
    required MembershipEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Update a Membership.',
      summary: 'Update Membership',
      operationId:
          'update_membership_phonebook_associations_memberships__membership_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Phonebook"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/phonebook/associations/memberships/${membershipId}',
    );
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _phonebookAssociationsMembershipsMembershipIdDelete({
    required String? membershipId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Delete a membership.',
      summary: 'Delete Membership',
      operationId:
          'delete_membership_phonebook_associations_memberships__membership_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Phonebook"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/phonebook/associations/memberships/${membershipId}',
    );
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<AppTypesStandardResponsesResult>>
  _phonebookAssociationsAssociationIdPicturePost({
    required String? associationId,
    required List<int> image,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Upload a logo for an Association.

**The user must be a member of the group phonebook_admin or the president of the association to use this endpoint**''',
      summary: 'Create Association Logo',
      operationId:
          'create_association_logo_phonebook_associations__association_id__picture_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Phonebook"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/phonebook/associations/${associationId}/picture',
    );
    final List<PartValue> $parts = <PartValue>[
      PartValueFile<List<int>>('image', image),
    ];
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parts: $parts,
      multipart: true,
      tag: swaggerMetaData,
    );
    return client
        .send<AppTypesStandardResponsesResult, AppTypesStandardResponsesResult>(
          $request,
        );
  }

  @override
  Future<Response<List<int>>> _phonebookAssociationsAssociationIdPictureGet({
    required String? associationId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get the logo of an Association.',
      summary: 'Read Association Logo',
      operationId:
          'read_association_logo_phonebook_associations__association_id__picture_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Phonebook"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/phonebook/associations/${associationId}/picture',
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<int>, int>($request);
  }

  @override
  Future<Response<RaidParticipant>> _raidParticipantsParticipantIdGet({
    required String? participantId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get a participant by id',
      summary: 'Get Participant By Id',
      operationId:
          'get_participant_by_id_raid_participants__participant_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raid"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/raid/participants/${participantId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<RaidParticipant, RaidParticipant>($request);
  }

  @override
  Future<Response<void>> _raidParticipantsParticipantIdPatch({
    required String? participantId,
    required RaidParticipantUpdate? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Update a participant',
      summary: 'Update Participant',
      operationId:
          'update_participant_raid_participants__participant_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raid"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/raid/participants/${participantId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<RaidParticipant>> _raidParticipantsPost({
    required RaidParticipantBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Create a participant',
      summary: 'Create Participant',
      operationId: 'create_participant_raid_participants_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raid"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/raid/participants');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<RaidParticipant, RaidParticipant>($request);
  }

  @override
  Future<Response<List<RaidTeamPreview>>> _raidTeamsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get all teams',
      summary: 'Get All Teams',
      operationId: 'get_all_teams_raid_teams_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raid"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/raid/teams');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<RaidTeamPreview>, RaidTeamPreview>($request);
  }

  @override
  Future<Response<RaidTeam>> _raidTeamsPost({
    required RaidTeamBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Create a team',
      summary: 'Create Team',
      operationId: 'create_team_raid_teams_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raid"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/raid/teams');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<RaidTeam, RaidTeam>($request);
  }

  @override
  Future<Response<void>> _raidTeamsDelete({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Delete all teams',
      summary: 'Delete All Teams',
      operationId: 'delete_all_teams_raid_teams_delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raid"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/raid/teams');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<RaidTeam>> _raidParticipantsParticipantIdTeamGet({
    required String? participantId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get a team by participant id',
      summary: 'Get Team By Participant Id',
      operationId:
          'get_team_by_participant_id_raid_participants__participant_id__team_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raid"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/raid/participants/${participantId}/team');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<RaidTeam, RaidTeam>($request);
  }

  @override
  Future<Response<RaidTeam>> _raidTeamsTeamIdGet({
    required String? teamId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get a team by id',
      summary: 'Get Team By Id',
      operationId: 'get_team_by_id_raid_teams__team_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raid"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/raid/teams/${teamId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<RaidTeam, RaidTeam>($request);
  }

  @override
  Future<Response<void>> _raidTeamsTeamIdPatch({
    required String? teamId,
    required RaidTeamUpdate? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Update a team',
      summary: 'Update Team',
      operationId: 'update_team_raid_teams__team_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raid"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/raid/teams/${teamId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _raidTeamsTeamIdDelete({
    required String? teamId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Delete a team',
      summary: 'Delete Team',
      operationId: 'delete_team_raid_teams__team_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raid"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/raid/teams/${teamId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<DocumentCreation>> _raidDocumentDocumentTypePost({
    required String? documentType,
    required List<int> file,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Upload a document',
      summary: 'Upload Document',
      operationId: 'upload_document_raid_document__document_type__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raid"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/raid/document/${documentType}');
    final List<PartValue> $parts = <PartValue>[
      PartValueFile<List<int>>('file', file),
    ];
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parts: $parts,
      multipart: true,
      tag: swaggerMetaData,
    );
    return client.send<DocumentCreation, DocumentCreation>($request);
  }

  @override
  Future<Response<List<int>>> _raidDocumentDocumentIdGet({
    required String? documentId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Read a document',
      summary: 'Read Document',
      operationId: 'read_document_raid_document__document_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raid"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/raid/document/${documentId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<int>, int>($request);
  }

  @override
  Future<Response<void>> _raidDocumentDocumentIdValidatePost({
    required String? documentId,
    required String? validation,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Validate a document',
      summary: 'Validate Document',
      operationId:
          'validate_document_raid_document__document_id__validate_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raid"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/raid/document/${documentId}/validate');
    final Map<String, dynamic> $params = <String, dynamic>{
      'validation': validation,
    };
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<SecurityFile>> _raidSecurityFilePost({
    required String? participantId,
    required SecurityFileBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Confirm security file',
      summary: 'Set Security File',
      operationId: 'set_security_file_raid_security_file__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raid"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/raid/security_file/');
    final Map<String, dynamic> $params = <String, dynamic>{
      'participant_id': participantId,
    };
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<SecurityFile, SecurityFile>($request);
  }

  @override
  Future<Response<void>> _raidParticipantParticipantIdPaymentPost({
    required String? participantId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Confirm payment manually',
      summary: 'Confirm Payment',
      operationId:
          'confirm_payment_raid_participant__participant_id__payment_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raid"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/raid/participant/${participantId}/payment');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _raidParticipantParticipantIdTShirtPaymentPost({
    required String? participantId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Confirm T shirt payment',
      summary: 'Confirm T Shirt Payment',
      operationId:
          'confirm_t_shirt_payment_raid_participant__participant_id__t_shirt_payment_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raid"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/raid/participant/${participantId}/t_shirt_payment',
    );
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _raidParticipantParticipantIdHonourPost({
    required String? participantId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Validate attestation on honour',
      summary: 'Validate Attestation On Honour',
      operationId:
          'validate_attestation_on_honour_raid_participant__participant_id__honour_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raid"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/raid/participant/${participantId}/honour');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<InviteToken>> _raidTeamsTeamIdInvitePost({
    required String? teamId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Create an invite token',
      summary: 'Create Invite Token',
      operationId: 'create_invite_token_raid_teams__team_id__invite_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raid"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/raid/teams/${teamId}/invite');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<InviteToken, InviteToken>($request);
  }

  @override
  Future<Response<void>> _raidTeamsJoinTokenPost({
    required String? token,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Join a team',
      summary: 'Join Team',
      operationId: 'join_team_raid_teams_join__token__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raid"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/raid/teams/join/${token}');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<RaidTeam>> _raidTeamsTeamIdKickParticipantIdPost({
    required String? teamId,
    required String? participantId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Leave a team',
      summary: 'Kick Team Member',
      operationId:
          'kick_team_member_raid_teams__team_id__kick__participant_id__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raid"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/raid/teams/${teamId}/kick/${participantId}');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<RaidTeam, RaidTeam>($request);
  }

  @override
  Future<Response<RaidTeam>> _raidTeamsMergePost({
    required String? team1Id,
    required String? team2Id,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Merge two teams',
      summary: 'Merge Teams',
      operationId: 'merge_teams_raid_teams_merge_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raid"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/raid/teams/merge');
    final Map<String, dynamic> $params = <String, dynamic>{
      'team1_id': team1Id,
      'team2_id': team2Id,
    };
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<RaidTeam, RaidTeam>($request);
  }

  @override
  Future<Response<RaidInformation>> _raidInformationGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get raid information',
      summary: 'Get Raid Information',
      operationId: 'get_raid_information_raid_information_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raid"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/raid/information');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<RaidInformation, RaidInformation>($request);
  }

  @override
  Future<Response<void>> _raidInformationPatch({
    required RaidInformation? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Update raid information',
      summary: 'Update Raid Information',
      operationId: 'update_raid_information_raid_information_patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raid"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/raid/information');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<RaidDriveFoldersCreation>> _raidDriveGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get drive folders',
      summary: 'Get Drive Folders',
      operationId: 'get_drive_folders_raid_drive_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raid"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/raid/drive');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<RaidDriveFoldersCreation, RaidDriveFoldersCreation>(
      $request,
    );
  }

  @override
  Future<Response<void>> _raidDrivePatch({
    required RaidDriveFoldersCreation? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Update drive folders',
      summary: 'Update Drive Folders',
      operationId: 'update_drive_folders_raid_drive_patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raid"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/raid/drive');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<RaidPrice>> _raidPriceGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get raid price',
      summary: 'Get Raid Price',
      operationId: 'get_raid_price_raid_price_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raid"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/raid/price');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<RaidPrice, RaidPrice>($request);
  }

  @override
  Future<Response<void>> _raidPricePatch({
    required RaidPrice? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Update raid price',
      summary: 'Update Raid Price',
      operationId: 'update_raid_price_raid_price_patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raid"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/raid/price');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<PaymentUrl>> _raidPayGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get payment url',
      summary: 'Get Payment Url',
      operationId: 'get_payment_url_raid_pay_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raid"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/raid/pay');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<PaymentUrl, PaymentUrl>($request);
  }

  @override
  Future<Response<List<int>>> _raidSecurityFilesZipGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Generate and serve a ZIP file containing all security files.
Only accessible to raid admins.''',
      summary: 'Download Security Files Zip',
      operationId: 'download_security_files_zip_raid_security_files_zip_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raid"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/raid/security_files_zip');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<int>, int>($request);
  }

  @override
  Future<Response<List<int>>> _raidTeamFilesZipGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Generate and serve a ZIP file containing all team files.
Only accessible to raid admins.''',
      summary: 'Download Team Files Zip',
      operationId: 'download_team_files_zip_raid_team_files_zip_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Raid"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/raid/team_files_zip');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<int>, int>($request);
  }

  @override
  Future<Response<List<EventCompleteTicketUrl>>> _calendarEventsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get all events from the database.',
      summary: 'Get Events',
      operationId: 'get_events_calendar_events__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Calendar"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/calendar/events/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<EventCompleteTicketUrl>, EventCompleteTicketUrl>(
      $request,
    );
  }

  @override
  Future<Response<EventCompleteTicketUrl>> _calendarEventsPost({
    required EventBaseCreation? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Add an event to the calendar.',
      summary: 'Add Event',
      operationId: 'add_event_calendar_events__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Calendar"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/calendar/events/');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<EventCompleteTicketUrl, EventCompleteTicketUrl>(
      $request,
    );
  }

  @override
  Future<Response<List<EventCompleteTicketUrl>>> _calendarEventsConfirmedGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get all confirmed events.

**Usable by every member**''',
      summary: 'Get Confirmed Events',
      operationId: 'get_confirmed_events_calendar_events_confirmed_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Calendar"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/calendar/events/confirmed');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<EventCompleteTicketUrl>, EventCompleteTicketUrl>(
      $request,
    );
  }

  @override
  Future<Response<List<EventCompleteTicketUrl>>>
  _calendarEventsAssociationsAssociationIdGet({
    required String? associationId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get the booking of the association

**Usable by members of the association**''',
      summary: 'Get Association Events',
      operationId:
          'get_association_events_calendar_events_associations__association_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Calendar"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/calendar/events/associations/${associationId}',
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<EventCompleteTicketUrl>, EventCompleteTicketUrl>(
      $request,
    );
  }

  @override
  Future<Response<EventCompleteTicketUrl>> _calendarEventsEventIdGet({
    required String? eventId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get an event\'s information by its id.

**Non approved events are only accessible for BDE or the event\'s association members**''',
      summary: 'Get Event By Id',
      operationId: 'get_event_by_id_calendar_events__event_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Calendar"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/calendar/events/${eventId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<EventCompleteTicketUrl, EventCompleteTicketUrl>(
      $request,
    );
  }

  @override
  Future<Response<void>> _calendarEventsEventIdPatch({
    required String? eventId,
    required EventEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Edit an event.

**Only usable by admins or members of the event\'s association**''',
      summary: 'Edit Event',
      operationId: 'edit_event_calendar_events__event_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Calendar"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/calendar/events/${eventId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _calendarEventsEventIdDelete({
    required Object? eventId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Remove an event.

**Only usable by admins or, if the event is pending, members of the event\'s association**''',
      summary: 'Delete Event',
      operationId: 'delete_event_calendar_events__event_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Calendar"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/calendar/events/${eventId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<EventTicketUrl>> _calendarEventsEventIdTicketUrlGet({
    required String? eventId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Event Ticket Url',
      operationId:
          'get_event_ticket_url_calendar_events__event_id__ticket_url_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Calendar"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/calendar/events/${eventId}/ticket-url');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<EventTicketUrl, EventTicketUrl>($request);
  }

  @override
  Future<Response<List<int>>> _calendarEventsEventIdImageGet({
    required String? eventId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get the image of an event

**The user must be authenticated to use this endpoint**''',
      summary: 'Get Event Image',
      operationId: 'get_event_image_calendar_events__event_id__image_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Calendar"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/calendar/events/${eventId}/image');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<int>, int>($request);
  }

  @override
  Future<Response<void>> _calendarEventsEventIdImagePost({
    required String? eventId,
    required List<int> image,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Add an image to an event

**The user must be authenticated to use this endpoint**''',
      summary: 'Create Event Image',
      operationId: 'create_event_image_calendar_events__event_id__image_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Calendar"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/calendar/events/${eventId}/image');
    final List<PartValue> $parts = <PartValue>[
      PartValueFile<List<int>>('image', image),
    ];
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parts: $parts,
      multipart: true,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _calendarEventsEventIdReplyDecisionPatch({
    required String? eventId,
    required String? decision,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Give a decision to an event.

**Only usable by admins**''',
      summary: 'Confirm Event',
      operationId:
          'confirm_event_calendar_events__event_id__reply__decision__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Calendar"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/calendar/events/${eventId}/reply/${decision}');
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<IcalSecret>> _calendarIcalUrlGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Generate a unique ical url for the user',
      summary: 'Get Ical Url',
      operationId: 'get_ical_url_calendar_ical_url_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Calendar"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/calendar/ical-url');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<IcalSecret, IcalSecret>($request);
  }

  @override
  Future<Response<void>> _calendarIcalCreatePost({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create manually the icalendar file

**Only usable by global admins**''',
      summary: 'Recreate Ical File',
      operationId: 'recreate_ical_file_calendar_ical_create_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Calendar"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/calendar/ical/create');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<int>>> _calendarIcalGet({
    required String? secret,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Get the icalendar file corresponding to the event in the database.',
      summary: 'Get Icalendar File',
      operationId: 'get_icalendar_file_calendar_ical_get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Calendar"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/calendar/ical');
    final Map<String, dynamic> $params = <String, dynamic>{'secret': secret};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<List<int>, int>($request);
  }

  @override
  Future<Response<List<News>>> _feedNewsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Return published news from the feed',
      summary: 'Get Published News',
      operationId: 'get_published_news_feed_news_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Feed"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/feed/news');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<News>, News>($request);
  }

  @override
  Future<Response<List<int>>> _feedNewsNewsIdImageGet({
    required String? newsId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Return the image of a news',
      summary: 'Get News Image',
      operationId: 'get_news_image_feed_news__news_id__image_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Feed"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/feed/news/${newsId}/image');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<int>, int>($request);
  }

  @override
  Future<Response<List<News>>> _feedAdminNewsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Return news from the feed

**This endpoint is only usable by feed administrators**''',
      summary: 'Get Admin News',
      operationId: 'get_admin_news_feed_admin_news_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Feed"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/feed/admin/news');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<News>, News>($request);
  }

  @override
  Future<Response<void>> _feedAdminNewsNewsIdApprovePost({
    required String? newsId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Approve a news

**This endpoint is only usable by feed administrators**''',
      summary: 'Approve News',
      operationId: 'approve_news_feed_admin_news__news_id__approve_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Feed"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/feed/admin/news/${newsId}/approve');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _feedAdminNewsNewsIdRejectPost({
    required String? newsId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Reject a news

**This endpoint is only usable by feed administrators**''',
      summary: 'Reject News',
      operationId: 'reject_news_feed_admin_news__news_id__reject_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Feed"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/feed/admin/news/${newsId}/reject');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<CoreSchool>>> _schoolsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Return all schools from database as a list of dictionaries',
      summary: 'Read Schools',
      operationId: 'read_schools_schools__get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Schools"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/schools/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<CoreSchool>, CoreSchool>($request);
  }

  @override
  Future<Response<CoreSchool>> _schoolsPost({
    required CoreSchoolBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Create a new school and add users to it based on the email regex.

**This endpoint is only usable by administrators**''',
      summary: 'Create School',
      operationId: 'create_school_schools__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Schools"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/schools/');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<CoreSchool, CoreSchool>($request);
  }

  @override
  Future<Response<CoreSchool>> _schoolsSchoolIdGet({
    required String? schoolId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Return school with id from database as a dictionary.

**This endpoint is only usable by administrators**''',
      summary: 'Read School',
      operationId: 'read_school_schools__school_id__get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Schools"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/schools/${schoolId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<CoreSchool, CoreSchool>($request);
  }

  @override
  Future<Response<void>> _schoolsSchoolIdPatch({
    required String? schoolId,
    required CoreSchoolUpdate? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Update the name or the description of a school.

**This endpoint is only usable by administrators**''',
      summary: 'Update School',
      operationId: 'update_school_schools__school_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Schools"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/schools/${schoolId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _schoolsSchoolIdDelete({
    required String? schoolId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Delete school from database.
This will remove the school from all users but won\'t delete any user.

`SchoolTypes` schools can not be deleted.

**This endpoint is only usable by administrators**''',
      summary: 'Delete School',
      operationId: 'delete_school_schools__school_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Schools"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/schools/${schoolId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<Association>>> _associationsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Return all associations

**User must be authenticated**''',
      summary: 'Read Associations',
      operationId: 'read_associations_associations__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Associations"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/associations/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<Association>, Association>($request);
  }

  @override
  Future<Response<Association>> _associationsPost({
    required AppCoreAssociationsSchemasAssociationsAssociationBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a new association

**This endpoint is only usable by administrators**''',
      summary: 'Create Association',
      operationId: 'create_association_associations__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Associations"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/associations/');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<Association, Association>($request);
  }

  @override
  Future<Response<List<Association>>> _associationsMeGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Return all associations the current user has the right to manage

**User must be authenticated**''',
      summary: 'Read Associations Me',
      operationId: 'read_associations_me_associations_me_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Associations"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/associations/me');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<Association>, Association>($request);
  }

  @override
  Future<Response<void>> _associationsAssociationIdPatch({
    required String? associationId,
    required AssociationUpdate? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Update the name or the description of a association.

**This endpoint is only usable by administrators**''',
      summary: 'Update Association',
      operationId: 'update_association_associations__association_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Associations"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/associations/${associationId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _associationsAssociationIdLogoPost({
    required String? associationId,
    required List<int> image,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Upload a logo for an association

**This endpoint is only usable by administrators**''',
      summary: 'Create Association Logo',
      operationId:
          'create_association_logo_associations__association_id__logo_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Associations"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/associations/${associationId}/logo');
    final List<PartValue> $parts = <PartValue>[
      PartValueFile<List<int>>('image', image),
    ];
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parts: $parts,
      multipart: true,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<int>>> _associationsAssociationIdLogoGet({
    required String? associationId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get the logo of an association

**User must be authenticated**''',
      summary: 'Read Association Logo',
      operationId:
          'read_association_logo_associations__association_id__logo_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Associations"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/associations/${associationId}/logo');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<int>, int>($request);
  }

  @override
  Future<Response<List<CoreUserSimple>>> _usersGet({
    List<Object?>? accountTypes,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Return all users from database as a list of `CoreUserSimple`

**This endpoint is only usable by administrators**''',
      summary: 'Read Users',
      operationId: 'read_users_users_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Users"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/users');
    final Map<String, dynamic> $params = <String, dynamic>{
      'accountTypes': accountTypes,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<List<CoreUserSimple>, CoreUserSimple>($request);
  }

  @override
  Future<Response<int>> _usersCountGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Return the number of users in the database

**This endpoint is only usable by administrators**''',
      summary: 'Count Users',
      operationId: 'count_users_users_count_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Users"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/users/count');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<int, int>($request);
  }

  @override
  Future<Response<List<CoreUserSimple>>> _usersSearchGet({
    required String? query,
    List<Object?>? includedAccountTypes,
    List<Object?>? excludedAccountTypes,
    List<String>? includedGroups,
    List<String>? excludedGroups,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Search for a user using Jaro_Winkler distance algorithm.
The `query` will be compared against users name, firstname and nickname.
Assume that `query` is the beginning of a name, so we can capitalize words to improve results.

**The user must be authenticated to use this endpoint**''',
      summary: 'Search Users',
      operationId: 'search_users_users_search_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Users"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/users/search');
    final Map<String, dynamic> $params = <String, dynamic>{
      'query': query,
      'includedAccountTypes': includedAccountTypes,
      'excludedAccountTypes': excludedAccountTypes,
      'includedGroups': includedGroups,
      'excludedGroups': excludedGroups,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<List<CoreUserSimple>, CoreUserSimple>($request);
  }

  @override
  Future<Response<List<String>>> _usersAccountTypesGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Return all account types hardcoded in the system',
      summary: 'Get Account Types',
      operationId: 'get_account_types_users_account_types__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Users"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/users/account-types/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<String>, String>($request);
  }

  @override
  Future<Response<CoreUser>> _usersMeGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Return `CoreUser` representation of current user

**The user must be authenticated to use this endpoint**''',
      summary: 'Read Current User',
      operationId: 'read_current_user_users_me_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Users"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/users/me');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<CoreUser, CoreUser>($request);
  }

  @override
  Future<Response<void>> _usersMePatch({
    required CoreUserUpdate? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Update the current user, the request should contain a JSON with the fields to change (not necessarily all fields) and their new value

**The user must be authenticated to use this endpoint**''',
      summary: 'Update Current User',
      operationId: 'update_current_user_users_me_patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Users"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/users/me');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<AppTypesStandardResponsesResult>> _usersCreatePost({
    required CoreUserCreateRequest? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Start the user account creation process. The user will be sent an email with a link to activate his account.
> The received token needs to be sent to the `/users/activate` endpoint to activate the account.

If the **password** is not provided, it will be required during the activation process. Don\'t submit a password if you are creating an account for someone else.

When creating **student** or **staff** account a valid ECL email is required.
Only admin users can create other **account types**, contact ÉCLAIR for more information.''',
      summary: 'Create User By User',
      operationId: 'create_user_by_user_users_create_post',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Users"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/users/create');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client
        .send<AppTypesStandardResponsesResult, AppTypesStandardResponsesResult>(
          $request,
        );
  }

  @override
  Future<Response<BatchResult>> _usersBatchCreationPost({
    required List<CoreBatchUserCreateRequest>? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Batch user account creation process. All users will be sent an email with a link to activate their account.
> The received token needs to be send to `/users/activate` endpoint to activate the account.

Even for creating **student** or **staff** account a valid ECL email is not required but should preferably be used.

The endpoint return a dictionary of unsuccessful user creation: `{email: error message}`.

NOTE: the activation link will only be valid for a limited time. You should probably use `/users/batch-invitation` endpoint instead, which will send an invitation email to the user.

**This endpoint is only usable by administrators**''',
      summary: 'Batch Create Users',
      operationId: 'batch_create_users_users_batch_creation_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Users"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/users/batch-creation');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<BatchResult, BatchResult>($request);
  }

  @override
  Future<Response<BatchResult>> _usersBatchInvitationPost({
    required List<CoreBatchUserCreateRequest>? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Batch user account invitation process. All users will be sent an email encouraging them to create an account.
These emails will be whitelisted in Hyperion. If self registration is disabled only whitelisted emails will be able to create an account.

The endpoint return a dictionary of unsuccessful user creation: `{email: error message}`.

**This endpoint is only usable by administrators**''',
      summary: 'Batch Invite Users',
      operationId: 'batch_invite_users_users_batch_invitation_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Users"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/users/batch-invitation');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<BatchResult, BatchResult>($request);
  }

  @override
  Future<Response<AppTypesStandardResponsesResult>> _usersActivatePost({
    required CoreUserActivateRequest? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Activate the previously created account.

**token**: the activation token sent by email to the user

**password**: user password, required if it was not provided previously''',
      summary: 'Activate User',
      operationId: 'activate_user_users_activate_post',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Users"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/users/activate');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client
        .send<AppTypesStandardResponsesResult, AppTypesStandardResponsesResult>(
          $request,
        );
  }

  @override
  Future<Response<void>> _usersS3InitPost({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''This endpoint is used to initialize the S3 bucket for users.
It will create a file for each existing user in the S3 bucket.
It should be used only once, when the S3 bucket is created.''',
      summary: 'Init S3 For Users',
      operationId: 'init_s3_for_users_users_s3_init_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Users"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/users/s3-init');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<AppTypesStandardResponsesResult>> _usersRecoverPost({
    required BodyRecoverUserUsersRecoverPost? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Allow a user to start a password reset process.

If the provided **email** corresponds to an existing account, a password reset token will be sent.
Using this token, the password can be changed with `/users/reset-password` endpoint''',
      summary: 'Recover User',
      operationId: 'recover_user_users_recover_post',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Users"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/users/recover');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client
        .send<AppTypesStandardResponsesResult, AppTypesStandardResponsesResult>(
          $request,
        );
  }

  @override
  Future<Response<AppTypesStandardResponsesResult>> _usersResetPasswordPost({
    required ResetPasswordRequest? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Reset the user password, using a **reset_token** provided by `/users/recover` endpoint.',
      summary: 'Reset Password',
      operationId: 'reset_password_users_reset_password_post',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Users"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/users/reset-password');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client
        .send<AppTypesStandardResponsesResult, AppTypesStandardResponsesResult>(
          $request,
        );
  }

  @override
  Future<Response<void>> _usersMigrateMailPost({
    required MailMigrationRequest? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'This endpoint will send a confirmation code to the user\'s new email address. He will need to use this code to confirm the change with `/users/confirm-mail-migration` endpoint.',
      summary: 'Migrate Mail',
      operationId: 'migrate_mail_users_migrate_mail_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Users"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/users/migrate-mail');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<String>> _usersMigrateMailConfirmGet({
    required String? token,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''This endpoint will updates the user new email address.
The user will need to use the confirmation code sent by the `/users/migrate-mail` endpoint.''',
      summary: 'Migrate Mail Confirm',
      operationId: 'migrate_mail_confirm_users_migrate_mail_confirm_get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Users"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/users/migrate-mail-confirm');
    final Map<String, dynamic> $params = <String, dynamic>{'token': token};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<String, String>($request);
  }

  @override
  Future<Response<AppTypesStandardResponsesResult>> _usersChangePasswordPost({
    required ChangePasswordRequest? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Change a user password.

This endpoint will check the **old_password**, see also the `/users/reset-password` endpoint if the user forgot their password.''',
      summary: 'Change Password',
      operationId: 'change_password_users_change_password_post',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Users"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/users/change-password');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client
        .send<AppTypesStandardResponsesResult, AppTypesStandardResponsesResult>(
          $request,
        );
  }

  @override
  Future<Response<CoreUser>> _usersUserIdGet({
    required String? userId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Return `CoreUser` representation of user with id `user_id`

**The user must be authenticated to use this endpoint**''',
      summary: 'Read User',
      operationId: 'read_user_users__user_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Users"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/users/${userId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<CoreUser, CoreUser>($request);
  }

  @override
  Future<Response<void>> _usersUserIdPatch({
    required String? userId,
    required CoreUserUpdateAdmin? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Update an user, the request should contain a JSON with the fields to change (not necessarily all fields) and their new value

**This endpoint is only usable by administrators**''',
      summary: 'Update User',
      operationId: 'update_user_users__user_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Users"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/users/${userId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _usersMeAskDeletionPost({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''This endpoint will ask administrators to process to the user deletion.
This manual verification is needed to prevent data from being deleting for other users''',
      summary: 'Delete User',
      operationId: 'delete_user_users_me_ask_deletion_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Users"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/users/me/ask-deletion');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _usersMergePost({
    required CoreUserFusionRequest? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Fusion two users into one. The first user will be deleted and its data will be transferred to the second user.',
      summary: 'Merge Users',
      operationId: 'merge_users_users_merge_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Users"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/users/merge');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _usersUserIdSuperAdminPatch({
    required String? userId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Update an user, the request should contain a JSON with the fields to change (not necessarily all fields) and their new value

**This endpoint is only usable by administrators**''',
      summary: 'Update User As Super Admin',
      operationId:
          'update_user_as_super_admin_users__user_id__super_admin_patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Users"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/users/${userId}/super-admin');
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<int>>> _usersMeProfilePictureGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get the profile picture of the authenticated user.',
      summary: 'Read Own Profile Picture',
      operationId: 'read_own_profile_picture_users_me_profile_picture_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Users"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/users/me/profile-picture');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<int>, int>($request);
  }

  @override
  Future<Response<AppTypesStandardResponsesResult>> _usersMeProfilePicturePost({
    required List<int> image,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Upload a profile picture for the current user.

**The user must be authenticated to use this endpoint**''',
      summary: 'Create Current User Profile Picture',
      operationId:
          'create_current_user_profile_picture_users_me_profile_picture_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Users"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/users/me/profile-picture');
    final List<PartValue> $parts = <PartValue>[
      PartValueFile<List<int>>('image', image),
    ];
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parts: $parts,
      multipart: true,
      tag: swaggerMetaData,
    );
    return client
        .send<AppTypesStandardResponsesResult, AppTypesStandardResponsesResult>(
          $request,
        );
  }

  @override
  Future<Response<List<int>>> _usersUserIdProfilePictureGet({
    required String? userId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get the profile picture of an user.

Unauthenticated users can use this endpoint (needed for some OIDC services)''',
      summary: 'Read User Profile Picture',
      operationId:
          'read_user_profile_picture_users__user_id__profile_picture_get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Users"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/users/${userId}/profile-picture');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<int>, int>($request);
  }

  @override
  Future<Response<void>> _checkoutHelloassoWebhookPost({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Webhook',
      operationId: 'webhook_checkout_helloasso_webhook_post',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Checkout"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/checkout/helloasso/webhook');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<MembershipSimple>>> _membershipsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Return all memberships from database as a list of dictionaries',
      summary: 'Read Associations Memberships',
      operationId: 'read_associations_memberships_memberships__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Memberships"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/memberships/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<MembershipSimple>, MembershipSimple>($request);
  }

  @override
  Future<Response<MembershipSimple>> _membershipsPost({
    required AppCoreMembershipsSchemasMembershipsMembershipBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a new membership.

**This endpoint is only usable by administrators**''',
      summary: 'Create Association Membership',
      operationId: 'create_association_membership_memberships__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Memberships"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/memberships/');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<MembershipSimple, MembershipSimple>($request);
  }

  @override
  Future<Response<List<UserMembershipComplete>>>
  _membershipsAssociationMembershipIdMembersGet({
    required String? associationMembershipId,
    String? minimalStartDate,
    String? maximalStartDate,
    String? minimalEndDate,
    String? maximalEndDate,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Return membership with the given ID.

**This endpoint is only usable by ECL members**''',
      summary: 'Read Association Membership',
      operationId:
          'read_association_membership_memberships__association_membership_id__members_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Memberships"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/memberships/${associationMembershipId}/members',
    );
    final Map<String, dynamic> $params = <String, dynamic>{
      'minimalStartDate': minimalStartDate,
      'maximalStartDate': maximalStartDate,
      'minimalEndDate': minimalEndDate,
      'maximalEndDate': maximalEndDate,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<List<UserMembershipComplete>, UserMembershipComplete>(
      $request,
    );
  }

  @override
  Future<Response<void>> _membershipsAssociationMembershipIdPatch({
    required String? associationMembershipId,
    required AppCoreMembershipsSchemasMembershipsMembershipBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Update a membership.

**This endpoint is only usable by administrators**''',
      summary: 'Update Association Membership',
      operationId:
          'update_association_membership_memberships__association_membership_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Memberships"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/memberships/${associationMembershipId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _membershipsAssociationMembershipIdDelete({
    required String? associationMembershipId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Delete a membership.

**This endpoint is only usable by administrators**''',
      summary: 'Delete Association Membership',
      operationId:
          'delete_association_membership_memberships__association_membership_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Memberships"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/memberships/${associationMembershipId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<UserMembershipComplete>>> _membershipsUsersUserIdGet({
    required String? userId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Return all memberships for a user.',
      summary: 'Read User Memberships',
      operationId: 'read_user_memberships_memberships_users__user_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Memberships"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/memberships/users/${userId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<UserMembershipComplete>, UserMembershipComplete>(
      $request,
    );
  }

  @override
  Future<Response<UserMembershipComplete>> _membershipsUsersUserIdPost({
    required String? userId,
    required UserMembershipBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a new user membership.

**This endpoint is only usable by administrators and membership managers**''',
      summary: 'Create User Membership',
      operationId: 'create_user_membership_memberships_users__user_id__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Memberships"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/memberships/users/${userId}');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<UserMembershipComplete, UserMembershipComplete>(
      $request,
    );
  }

  @override
  Future<Response<List<UserMembershipComplete>>>
  _membershipsUsersUserIdAssociationMembershipIdGet({
    required String? userId,
    required String? associationMembershipId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Return all user memberships for a specific association membership for a user.

**This endpoint is only usable by administrators and membership managers**''',
      summary: 'Read User Association Membership History',
      operationId:
          'read_user_association_membership_history_memberships_users__user_id___association_membership_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Memberships"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/memberships/users/${userId}/${associationMembershipId}',
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<UserMembershipComplete>, UserMembershipComplete>(
      $request,
    );
  }

  @override
  Future<Response<List<MembershipUserMappingEmail>>>
  _membershipsAssociationMembershipIdAddBatchPost({
    required String? associationMembershipId,
    required List<MembershipUserMappingEmail>? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Add a batch of user to a membership.

Return the list of unknown users whose email is not in the database.

**User must be an administrator or a membership manager to use this endpoint.**''',
      summary: 'Add Batch Membership',
      operationId:
          'add_batch_membership_memberships__association_membership_id__add_batch__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Memberships"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/memberships/${associationMembershipId}/add-batch/',
    );
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client
        .send<List<MembershipUserMappingEmail>, MembershipUserMappingEmail>(
          $request,
        );
  }

  @override
  Future<Response<void>> _membershipsUsersMembershipIdPatch({
    required String? membershipId,
    required UserMembershipEdit? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Update a user membership.

**This endpoint is only usable by administrators and membership managers**''',
      summary: 'Update User Membership',
      operationId:
          'update_user_membership_memberships_users__membership_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Memberships"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/memberships/users/${membershipId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _membershipsUsersMembershipIdDelete({
    required String? membershipId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Delete a user membership.

**This endpoint is only usable by administrators and membership managers**''',
      summary: 'Delete User Membership',
      operationId:
          'delete_user_membership_memberships_users__membership_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Memberships"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/memberships/users/${membershipId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _membershipsMembershipIdGroupGroupIdSynchronizePost({
    required String? membershipId,
    required String? groupId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Synchronize a membership with a group.

**This endpoint is only usable by administrators**''',
      summary: 'Synchronize Membership With Group',
      operationId:
          'synchronize_membership_with_group_memberships__membership_id__group__group_id__synchronize_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Memberships"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/memberships/${membershipId}/group/${groupId}/synchronize',
    );
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<CoreGroupSimple>>> _groupsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Return all groups from database as a list of dictionaries',
      summary: 'Read Groups',
      operationId: 'read_groups_groups__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Groups"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/groups/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<CoreGroupSimple>, CoreGroupSimple>($request);
  }

  @override
  Future<Response<CoreGroupSimple>> _groupsPost({
    required CoreGroupCreate? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a new group.

**This endpoint is only usable by administrators**''',
      summary: 'Create Group',
      operationId: 'create_group_groups__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Groups"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/groups/');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<CoreGroupSimple, CoreGroupSimple>($request);
  }

  @override
  Future<Response<CoreGroup>> _groupsGroupIdGet({
    required String? groupId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Return group with id from database as a dictionary. This includes a list of users being members of the group.

**This endpoint is only usable by administrators**''',
      summary: 'Read Group',
      operationId: 'read_group_groups__group_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Groups"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/groups/${groupId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<CoreGroup, CoreGroup>($request);
  }

  @override
  Future<Response<void>> _groupsGroupIdPatch({
    required String? groupId,
    required CoreGroupUpdate? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Update the name or the description of a group.

**This endpoint is only usable by administrators**''',
      summary: 'Update Group',
      operationId: 'update_group_groups__group_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Groups"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/groups/${groupId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _groupsGroupIdDelete({
    required String? groupId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Delete group from database.
This will remove the group from all users but won\'t delete any user.

`GroupTypes` groups can not be deleted.

**This endpoint is only usable by administrators**''',
      summary: 'Delete Group',
      operationId: 'delete_group_groups__group_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Groups"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/groups/${groupId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<CoreGroup>> _groupsMembershipPost({
    required CoreMembership? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Create a new membership in database and return the group. This allows to "add a user to a group".

**This endpoint is only usable by administrators**''',
      summary: 'Create Membership',
      operationId: 'create_membership_groups_membership_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Groups"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/groups/membership');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<CoreGroup, CoreGroup>($request);
  }

  @override
  Future<Response<void>> _groupsMembershipDelete({
    required CoreMembershipDelete? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Delete a membership using the user and group ids.

**This endpoint is only usable by administrators**''',
      summary: 'Delete Membership',
      operationId: 'delete_membership_groups_membership_delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Groups"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/groups/membership');
    final $body = body;
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _groupsBatchMembershipPost({
    required CoreBatchMembership? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Add a list of user to a group, using a list of email.
If an user does not exist it will be ignored.

**This endpoint is only usable by administrators**''',
      summary: 'Create Batch Membership',
      operationId: 'create_batch_membership_groups_batch_membership_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Groups"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/groups/batch-membership');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _groupsBatchMembershipDelete({
    required CoreBatchDeleteMembership? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''This endpoint removes all users from a given group.

**This endpoint is only usable by administrators**''',
      summary: 'Delete Batch Membership',
      operationId: 'delete_batch_membership_groups_batch_membership_delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Groups"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/groups/batch-membership');
    final $body = body;
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _groupsGroupIdLogoPost({
    required String? groupId,
    required List<int> image,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Upload a logo for a group.

**This endpoint is only usable by administrators**''',
      summary: 'Create Group Logo',
      operationId: 'create_group_logo_groups__group_id__logo_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Groups"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/groups/${groupId}/logo');
    final List<PartValue> $parts = <PartValue>[
      PartValueFile<List<int>>('image', image),
    ];
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parts: $parts,
      multipart: true,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<int>>> _groupsGroupIdLogoGet({
    required String? groupId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get the logo of a group.

**User must be authenticated**''',
      summary: 'Read User Profile Picture',
      operationId: 'read_user_profile_picture_groups__group_id__logo_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Groups"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/groups/${groupId}/logo');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<int>, int>($request);
  }

  @override
  Future<Response<CoreInformation>> _informationGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Return information about Hyperion. This endpoint can be used to check if the API is up.',
      summary: 'Read Information',
      operationId: 'read_information_information_get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Core"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/information');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<CoreInformation, CoreInformation>($request);
  }

  @override
  Future<Response<String>> _privacyGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Return Hyperion privacy',
      summary: 'Read Privacy',
      operationId: 'read_privacy_privacy_get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Core"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/privacy');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<String, String>($request);
  }

  @override
  Future<Response<String>> _termsAndConditionsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Return Hyperion terms and conditions pages',
      summary: 'Read Terms And Conditions',
      operationId: 'read_terms_and_conditions_terms_and_conditions_get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Core"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/terms-and-conditions');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<String, String>($request);
  }

  @override
  Future<Response<String>> _mypaymentTermsOfServiceGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Return MyPayment latest ToS',
      summary: 'Read Mypayment Tos',
      operationId: 'read_mypayment_tos_mypayment_terms_of_service_get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Core"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment-terms-of-service');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<String, String>($request);
  }

  @override
  Future<Response<String>> _supportGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Return Hyperion support',
      summary: 'Read Support',
      operationId: 'read_support_support_get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Core"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/support');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<String, String>($request);
  }

  @override
  Future<Response<String>> _securityTxtGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Return Hyperion security.txt file',
      summary: 'Read Security Txt',
      operationId: 'read_security_txt_security_txt_get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Core"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/security.txt');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<String, String>($request);
  }

  @override
  Future<Response<String>> _wellKnownSecurityTxtGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Return Hyperion security.txt file',
      summary: 'Read Wellknown Security Txt',
      operationId: 'read_wellknown_security_txt__well_known_security_txt_get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Core"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/.well-known/security.txt');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<String, String>($request);
  }

  @override
  Future<Response<String>> _robotsTxtGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Return Hyperion robots.txt file',
      summary: 'Read Robots Txt',
      operationId: 'read_robots_txt_robots_txt_get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Core"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/robots.txt');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<String, String>($request);
  }

  @override
  Future<Response<String>> _accountDeletionGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Return Hyperion account deletion information',
      summary: 'Read Account Deletion',
      operationId: 'read_account_deletion_account_deletion_get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Core"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/account-deletion');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<String, String>($request);
  }

  @override
  Future<Response<CoreVariables>> _variablesGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Return a style file from the assets folder',
      summary: 'Get Variables',
      operationId: 'get_variables_variables_get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Core"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/variables');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<CoreVariables, CoreVariables>($request);
  }

  @override
  Future<Response<List<int>>> _faviconIcoGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Favicon',
      operationId: 'get_favicon_favicon_ico_get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Core"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/favicon.ico');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<int>, int>($request);
  }

  @override
  Future<Response<AccessToken>> _authSimpleTokenPost({
    required Map<String, String> body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Ask for a JWT access token using oauth password flow.

*username* and *password* must be provided

Note: the request body needs to use **form-data** and not json.''',
      summary: 'Login For Access Token',
      operationId: 'login_for_access_token_auth_simple_token_post',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Auth"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/auth/simple_token');
    final Map<String, String> $headers = {
      'content-type': 'application/x-www-form-urlencoded',
    };
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      headers: $headers,
      tag: swaggerMetaData,
    );
    return client.send<AccessToken, AccessToken>(
      $request,
      requestConverter: FormUrlEncodedConverter.requestFactory,
    );
  }

  @override
  Future<Response<String>> _authAuthorizeGet({
    required String? clientId,
    String? redirectUri,
    required String? responseType,
    String? scope,
    String? state,
    String? nonce,
    String? codeChallenge,
    String? codeChallengeMethod,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''This endpoint is the one the user is redirected to when they begin the Oauth or Openid connect (*oidc*) *Authorization code* process.
The page allows the user to login and may let the user choose what type of data they want to authorize the client for.

This is the endpoint that should be set in the client OAuth or OIDC configuration page. It can be called by a GET or a POST request.

See `/auth/authorization-flow/authorize-validation` endpoint for information about the parameters.

> In order for the authorization code grant to be secure, the authorization page must appear in a web browser the user is familiar with,
> and must not be embedded in an iframe popup or an embedded browser in a mobile app.
> If it could be embedded in another website, the user would have no way of verifying it is the legitimate service and is not a phishing attempt.

**This endpoint is a UI endpoint which send and html page response. It will redirect to `/auth/authorization-flow/authorize-validation`**''',
      summary: 'Get Authorize Page',
      operationId: 'get_authorize_page_auth_authorize_get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Auth"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/auth/authorize');
    final Map<String, dynamic> $params = <String, dynamic>{
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'response_type': responseType,
      'scope': scope,
      'state': state,
      'nonce': nonce,
      'code_challenge': codeChallenge,
      'code_challenge_method': codeChallengeMethod,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<String, String>($request);
  }

  @override
  Future<Response<String>> _authAuthorizePost({
    required Map<String, String> body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''This endpoint is the one the user is redirected to when they begin the OAuth or Openid connect (*oidc*) *Authorization code* process with or without PKCE.
The page allows the user to login and may let the user choose what type of data they want to authorize the client for.

This is the endpoint that should be set in the client OAuth or OIDC configuration page. It can be called by a GET or a POST request.

See `/auth/authorization-flow/authorize-validation` endpoint for information about the parameters.

> In order for the authorization code grant to be secure, the authorization page must appear in a web browser the user is familiar with,
> and must not be embedded in an iframe popup or an embedded browser in a mobile app.
> If it could be embedded in another website, the user would have no way of verifying it is the legitimate service and is not a phishing attempt.

**This endpoint is a UI endpoint which send and html page response. It will redirect to `/auth/authorization-flow/authorize-validation`**''',
      summary: 'Post Authorize Page',
      operationId: 'post_authorize_page_auth_authorize_post',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Auth"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/auth/authorize');
    final Map<String, String> $headers = {
      'content-type': 'application/x-www-form-urlencoded',
    };
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      headers: $headers,
      tag: swaggerMetaData,
    );
    return client.send<String, String>(
      $request,
      requestConverter: FormUrlEncodedConverter.requestFactory,
    );
  }

  @override
  Future<Response<dynamic>> _authAuthorizationFlowAuthorizeValidationPost({
    required Map<String, String> body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Part 1 of the authorization code grant.

Parameters must be `application/x-www-form-urlencoded` and includes:

* parameters for OAuth and Openid connect:
    * `response_type`: must be `code`
    * `client_id`: client identifier, needs to be registered in the server known_clients
    * `redirect_uri`: optional for OAuth (when registered in known_clients) but required for oidc. The url we need to redirect the user to after the authorization.
    * `scope`: optional for OAuth, must contain "openid" for oidc. List of scope the client want to get access to.
    * `state`: recommended. Opaque value used to maintain state between the request and the callback.

* additional parameters for Openid connect:
    * `nonce`: oidc only. A string value used to associate a client session with an ID Token, and to mitigate replay attacks.

* additional parameters for PKCE (see specs on https://datatracker.ietf.org/doc/html/rfc7636/):
    * `code_challenge`: PKCE only
    * `code_challenge_method`: PKCE only


* parameters that allows to authenticate the user and know which scopes he grants access to.
    * `email`
    * `password`

References:
 * https://www.rfc-editor.org/rfc/rfc6749.html#section-4.1.2
 * https://openid.net/specs/openid-connect-core-1_0.html#AuthRequest''',
      summary: 'Authorize Validation',
      operationId:
          'authorize_validation_auth_authorization_flow_authorize_validation_post',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Auth"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/auth/authorization-flow/authorize-validation');
    final Map<String, String> $headers = {
      'content-type': 'application/x-www-form-urlencoded',
    };
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      headers: $headers,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>(
      $request,
      requestConverter: FormUrlEncodedConverter.requestFactory,
    );
  }

  @override
  Future<Response<TokenResponse>> _authTokenPost({
    String? authorization,
    required Map<String, String> body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Part 2 of the authorization code grant.
The client exchange its authorization code for an access token. The endpoint supports OAuth and Openid connect, with or without PKCE.

Parameters must be `application/x-www-form-urlencoded` and include:

* parameters for OAuth and Openid connect:
    * `grant_type`: must be `authorization_code` or `refresh_token`
    * `code`: the authorization code received from the authorization endpoint
    * `redirect_uri`: optional for OAuth (when registered in known_clients) but required for oidc. The url we need to redirect the user to after the authorization. If provided, must be the same as previously registered in the `redirect_uri` field of the client.

* Client credentials
    The client must send either:
        the client id and secret in the authorization header or with client_id and client_secret parameters

* additional parameters for PKCE:
    * `code_verifier`: PKCE only, allows to verify the previous code_challenge

https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.3
https://openid.net/specs/openid-connect-core-1_0.html#TokenRequestValidation''',
      summary: 'Token',
      operationId: 'token_auth_token_post',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Auth"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/auth/token');
    final Map<String, String> $headers = {
      if (authorization != null) 'authorization': authorization,
      'content-type': 'application/x-www-form-urlencoded',
    };
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      headers: $headers,
      tag: swaggerMetaData,
    );
    return client.send<TokenResponse, TokenResponse>(
      $request,
      requestConverter: FormUrlEncodedConverter.requestFactory,
    );
  }

  @override
  Future<Response<IntrospectTokenResponse>> _authIntrospectPost({
    String? authorization,
    required Map<String, String> body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Some clients requires an endpoint to check if an access token or a refresh token is valid.
This endpoint should not be publicly accessible, and is thus restricted to some AuthClient.

* parameters:
    * `token`: the token to introspect
    * `token_type_hint`: may be `access_token` or `refresh_token`, we currently do not use this hint as we are able to differentiate access and refresh tokens

* Client credentials
    The client must send either:
        the client id and secret in the authorization header or with client_id and client_secret parameters

Reference:
https://www.oauth.com/oauth2-servers/token-introspection-endpoint/
https://datatracker.ietf.org/doc/html/rfc7662''',
      summary: 'Introspect',
      operationId: 'introspect_auth_introspect_post',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Auth"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/auth/introspect');
    final Map<String, String> $headers = {
      if (authorization != null) 'authorization': authorization,
      'content-type': 'application/x-www-form-urlencoded',
    };
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      headers: $headers,
      tag: swaggerMetaData,
    );
    return client.send<IntrospectTokenResponse, IntrospectTokenResponse>(
      $request,
      requestConverter: FormUrlEncodedConverter.requestFactory,
    );
  }

  @override
  Future<Response<Object>> _authUserinfoGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Openid connect specify an endpoint the client can use to get information about the user.
The oidc client will provide the access_token it got previously in the request.

The information expected depends on the client and may include the user identifier, name, email, phone...
See the reference for possible claims. See the client documentation and implementation to know what it needs and can receive.
The sub (subject) Claim MUST always be returned in the UserInfo Response.

The client can ask for specific information using scopes and claims. See the reference for more information.
This procedure is not implemented in Hyperion as we can customize the response using auth_client class

Reference:
https://openid.net/specs/openid-connect-core-1_0.html#UserInfo''',
      summary: 'Auth Get Userinfo',
      operationId: 'auth_get_userinfo_auth_userinfo_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Auth"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/auth/userinfo');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<Object, Object>($request);
  }

  @override
  Future<Response<dynamic>> _oidcAuthorizationFlowJwksUriGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Jwks Uri',
      operationId: 'jwks_uri_oidc_authorization_flow_jwks_uri_get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Auth"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/oidc/authorization-flow/jwks_uri');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> _wellKnownOauthAuthorizationServerGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Oauth Configuration',
      operationId:
          'oauth_configuration__well_known_oauth_authorization_server_get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Auth"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/.well-known/oauth-authorization-server');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> _wellKnownOpenidConfigurationGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Oidc Configuration',
      operationId: 'oidc_configuration__well_known_openid_configuration_get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Auth"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/.well-known/openid-configuration');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<void>> _notificationDevicesPost({
    required BodyRegisterFirebaseDeviceNotificationDevicesPost? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Register a firebase device for the user, if the device already exists, this will update the creation date.
This endpoint should be called once a month to ensure that the token is still valide.

**The user must be authenticated to use this endpoint**''',
      summary: 'Register Firebase Device',
      operationId: 'register_firebase_device_notification_devices_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Notifications"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/notification/devices');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<FirebaseDevice>>> _notificationDevicesGet({
    String? userId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get all devices a user have registered.
This endpoint is useful to get firebase tokens for debugging purposes.

**Only admins can use this endpoint**''',
      summary: 'Get Devices',
      operationId: 'get_devices_notification_devices_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Notifications"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/notification/devices');
    final Map<String, dynamic> $params = <String, dynamic>{'user_id': userId};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<List<FirebaseDevice>, FirebaseDevice>($request);
  }

  @override
  Future<Response<void>> _notificationDevicesFirebaseTokenDelete({
    required String? firebaseToken,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Unregister a firebase device for the user

**The user must be authenticated to use this endpoint**''',
      summary: 'Unregister Firebase Device',
      operationId:
          'unregister_firebase_device_notification_devices__firebase_token__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Notifications"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/notification/devices/${firebaseToken}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _notificationTopicsTopicIdSubscribePost({
    required String? topicId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Subscribe to a topic.

If the topic define restrictions, the user must be in the corresponding group or be a member.

**The user must be authenticated to use this endpoint**''',
      summary: 'Subscribe To Topic',
      operationId:
          'subscribe_to_topic_notification_topics__topic_id__subscribe_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Notifications"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/notification/topics/${topicId}/subscribe');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _notificationTopicsTopicIdUnsubscribePost({
    required String? topicId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Unsubscribe to a topic

**The user must be authenticated to use this endpoint**''',
      summary: 'Unsubscribe To Topic',
      operationId:
          'unsubscribe_to_topic_notification_topics__topic_id__unsubscribe_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Notifications"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/notification/topics/${topicId}/unsubscribe');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<TopicUser>>> _notificationTopicsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Return all available topics for a user

**The user must be authenticated to use this endpoint**''',
      summary: 'Get Topics',
      operationId: 'get_topics_notification_topics_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Notifications"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/notification/topics');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<TopicUser>, TopicUser>($request);
  }

  @override
  Future<Response<void>> _notificationSendPost({
    required GroupNotificationRequest? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Send a notification to a group.

**Only admins can use this endpoint**''',
      summary: 'Send Notification',
      operationId: 'send_notification_notification_send_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Notifications"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/notification/send');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _notificationTestSendPost({
    String? userId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Send ourself a test notification.

**Only admins can use this endpoint**''',
      summary: 'Send Test Notification',
      operationId: 'send_test_notification_notification_test_send_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Notifications"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/notification/test/send');
    final Map<String, dynamic> $params = <String, dynamic>{'user_id': userId};
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _notificationTestSendFuturePost({
    String? userId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Send ourself a test notification.

**Only admins can use this endpoint**''',
      summary: 'Send Test Future Notification',
      operationId:
          'send_test_future_notification_notification_test_send_future_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Notifications"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/notification/test/send/future');
    final Map<String, dynamic> $params = <String, dynamic>{'user_id': userId};
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _notificationTestSendTopicPost({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Send ourself a test notification.

**Only admins can use this endpoint**''',
      summary: 'Send Test Notification Topic',
      operationId:
          'send_test_notification_topic_notification_test_send_topic_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Notifications"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/notification/test/send/topic');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _notificationTestSendTopicFuturePost({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Send ourself a test notification.

**Only admins can use this endpoint**''',
      summary: 'Send Test Future Notification Topic',
      operationId:
          'send_test_future_notification_topic_notification_test_send_topic_future_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Notifications"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/notification/test/send/topic/future');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<Structure>> _mypaymentBankAccountHolderGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get the current bank account holder information.',
      summary: 'Get Bank Account Holder',
      operationId: 'get_bank_account_holder_mypayment_bank_account_holder_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment/bank-account-holder');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<Structure, Structure>($request);
  }

  @override
  Future<Response<Structure>> _mypaymentBankAccountHolderPost({
    required MyPaymentBankAccountHolder? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Set the bank account holder information.',
      summary: 'Set Bank Account Holder',
      operationId: 'set_bank_account_holder_mypayment_bank_account_holder_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment/bank-account-holder');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<Structure, Structure>($request);
  }

  @override
  Future<Response<List<Structure>>> _mypaymentStructuresGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get all structures.',
      summary: 'Get Structures',
      operationId: 'get_structures_mypayment_structures_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment/structures');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<Structure>, Structure>($request);
  }

  @override
  Future<Response<Structure>> _mypaymentStructuresPost({
    required StructureBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a new structure.

A structure contains:
 - a name
 - an association membership id
 - a manager user id
 - a list of stores

**The user must be an admin to use this endpoint**''',
      summary: 'Create Structure',
      operationId: 'create_structure_mypayment_structures_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment/structures');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<Structure, Structure>($request);
  }

  @override
  Future<Response<void>> _mypaymentStructuresStructureIdPatch({
    required String? structureId,
    required StructureUpdate? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Update a structure.

**The user must be an admin to use this endpoint**''',
      summary: 'Update Structure',
      operationId: 'update_structure_mypayment_structures__structure_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment/structures/${structureId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _mypaymentStructuresStructureIdDelete({
    required String? structureId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Delete a structure. Only structures without stores can be deleted.

**The user must be an admin to use this endpoint**''',
      summary: 'Delete Structure',
      operationId:
          'delete_structure_mypayment_structures__structure_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment/structures/${structureId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>>
  _mypaymentStructuresStructureIdInitManagerTransferPost({
    required String? structureId,
    required StructureTranfert? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Initiate the transfer of a structure to a new manager. The current manager will receive an email with a link to confirm the transfer.
The link will only be valid for a limited time.

**The user must be the manager for this structure**''',
      summary: 'Init Transfer Structure Manager',
      operationId:
          'init_transfer_structure_manager_mypayment_structures__structure_id__init_manager_transfer_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/mypayment/structures/${structureId}/init-manager-transfer',
    );
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<dynamic>> _mypaymentStructuresConfirmManagerTransferGet({
    required String? token,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Update a manager for an association

The user must have initiated the update of the manager with `init_update_structure_manager`''',
      summary: 'Confirm Structure Manager Transfer',
      operationId:
          'confirm_structure_manager_transfer_mypayment_structures_confirm_manager_transfer_get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/mypayment/structures/confirm-manager-transfer',
    );
    final Map<String, dynamic> $params = <String, dynamic>{'token': token};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<Store>> _mypaymentStructuresStructureIdStoresPost({
    required String? structureId,
    required StoreBase? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Create a store. The structure manager will be added as a seller for the store.

Stores name should be unique, as an user need to be able to identify a store by its name.

**The user must be the manager for this structure**
**The user must be a member of the associated CoreAssociation**''',
      summary: 'Create Store',
      operationId:
          'create_store_mypayment_structures__structure_id__stores_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment/structures/${structureId}/stores');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<Store, Store>($request);
  }

  @override
  Future<Response<List<History>>> _mypaymentStoresStoreIdHistoryGet({
    required String? storeId,
    String? startDate,
    String? endDate,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get all transactions for the store.

**The user must be authorized to see the store history**''',
      summary: 'Get Store History',
      operationId: 'get_store_history_mypayment_stores__store_id__history_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment/stores/${storeId}/history');
    final Map<String, dynamic> $params = <String, dynamic>{
      'start_date': startDate,
      'end_date': endDate,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<List<History>, History>($request);
  }

  @override
  Future<Response<dynamic>> _mypaymentStoresStoreIdHistoryDataExportGet({
    required String? storeId,
    String? startDate,
    String? endDate,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Export store payment history as a CSV file.',
      summary: 'Export Store History',
      operationId:
          'export_store_history_mypayment_stores__store_id__history_data_export_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/mypayment/stores/${storeId}/history/data-export',
    );
    final Map<String, dynamic> $params = <String, dynamic>{
      'start_date': startDate,
      'end_date': endDate,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<List<UserStore>>> _mypaymentUsersMeStoresGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get all stores for the current user.

**The user must be authenticated to use this endpoint**''',
      summary: 'Get User Stores',
      operationId: 'get_user_stores_mypayment_users_me_stores_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment/users/me/stores');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<UserStore>, UserStore>($request);
  }

  @override
  Future<Response<void>> _mypaymentStoresStoreIdPatch({
    required String? storeId,
    required StoreUpdate? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Update a store

**The user must be the manager for this store\'s structure**''',
      summary: 'Update Store',
      operationId: 'update_store_mypayment_stores__store_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment/stores/${storeId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _mypaymentStoresStoreIdDelete({
    required String? storeId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Delete a store. Only stores without transactions can be deleted.

**The user must be the manager for this store\'s structure**''',
      summary: 'Delete Store',
      operationId: 'delete_store_mypayment_stores__store_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment/stores/${storeId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<Seller>> _mypaymentStoresStoreIdSellersPost({
    required String? storeId,
    required SellerCreation? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a store seller.

This seller will have authorized permissions among:
- can_bank
- can_see_history
- can_cancel
- can_manage_sellers

**The user must have the `can_manage_sellers` permission for this store**''',
      summary: 'Create Store Seller',
      operationId:
          'create_store_seller_mypayment_stores__store_id__sellers_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment/stores/${storeId}/sellers');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<Seller, Seller>($request);
  }

  @override
  Future<Response<List<Seller>>> _mypaymentStoresStoreIdSellersGet({
    required String? storeId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get all sellers for the given store.

**The user must have the `can_manage_sellers` permission for this store**''',
      summary: 'Get Store Sellers',
      operationId: 'get_store_sellers_mypayment_stores__store_id__sellers_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment/stores/${storeId}/sellers');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<Seller>, Seller>($request);
  }

  @override
  Future<Response<void>> _mypaymentStoresStoreIdSellersSellerUserIdPatch({
    required String? storeId,
    required String? sellerUserId,
    required SellerUpdate? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Update a store seller permissions.
The structure manager cannot be updated as a seller.

**The user must have the `can_manage_sellers` permission for this store**''',
      summary: 'Update Store Seller',
      operationId:
          'update_store_seller_mypayment_stores__store_id__sellers__seller_user_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/mypayment/stores/${storeId}/sellers/${sellerUserId}',
    );
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _mypaymentStoresStoreIdSellersSellerUserIdDelete({
    required String? storeId,
    required String? sellerUserId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Delete a store seller.
The structure manager cannot be deleted as a seller.

**The user must have the `can_manage_sellers` permission for this store**''',
      summary: 'Delete Store Seller',
      operationId:
          'delete_store_seller_mypayment_stores__store_id__sellers__seller_user_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/mypayment/stores/${storeId}/sellers/${sellerUserId}',
    );
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _mypaymentUsersMeRegisterPost({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Sign MyPayment TOS for the given user.

The user will need to accept the latest TOS version to be able to use MyPayment.

**The user must be authenticated to use this endpoint**''',
      summary: 'Register User',
      operationId: 'register_user_mypayment_users_me_register_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment/users/me/register');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<TOSSignatureResponse>> _mypaymentUsersMeTosGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Get the latest TOS version and the user signed TOS version.

**The user must be authenticated to use this endpoint**''',
      summary: 'Get User Tos',
      operationId: 'get_user_tos_mypayment_users_me_tos_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment/users/me/tos');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<TOSSignatureResponse, TOSSignatureResponse>($request);
  }

  @override
  Future<Response<void>> _mypaymentUsersMeTosPost({
    required TOSSignature? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Sign MyPayment TOS for the given user.

If the user is already registered in the MyPayment system, this will update the TOS version.

**The user must be authenticated to use this endpoint**''',
      summary: 'Sign Tos',
      operationId: 'sign_tos_mypayment_users_me_tos_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment/users/me/tos');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<WalletDevice>>> _mypaymentUsersMeWalletDevicesGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get user devices.

**The user must be authenticated to use this endpoint**''',
      summary: 'Get User Devices',
      operationId: 'get_user_devices_mypayment_users_me_wallet_devices_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment/users/me/wallet/devices');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<WalletDevice>, WalletDevice>($request);
  }

  @override
  Future<Response<WalletDevice>> _mypaymentUsersMeWalletDevicesPost({
    required WalletDeviceCreation? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a new device for the user.
The user will need to activate it using a token sent by email.

**The user must be authenticated to use this endpoint**''',
      summary: 'Create User Devices',
      operationId: 'create_user_devices_mypayment_users_me_wallet_devices_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment/users/me/wallet/devices');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<WalletDevice, WalletDevice>($request);
  }

  @override
  Future<Response<WalletDevice>>
  _mypaymentUsersMeWalletDevicesWalletDeviceIdGet({
    required String? walletDeviceId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get user devices.

**The user must be authenticated to use this endpoint**''',
      summary: 'Get User Device',
      operationId:
          'get_user_device_mypayment_users_me_wallet_devices__wallet_device_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/mypayment/users/me/wallet/devices/${walletDeviceId}',
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<WalletDevice, WalletDevice>($request);
  }

  @override
  Future<Response<Wallet>> _mypaymentUsersMeWalletGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get user wallet.

**The user must be authenticated to use this endpoint**''',
      summary: 'Get User Wallet',
      operationId: 'get_user_wallet_mypayment_users_me_wallet_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment/users/me/wallet');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<Wallet, Wallet>($request);
  }

  @override
  Future<Response<dynamic>> _mypaymentDevicesActivateGet({
    required String? token,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Activate a wallet device',
      summary: 'Activate User Device',
      operationId: 'activate_user_device_mypayment_devices_activate_get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment/devices/activate');
    final Map<String, dynamic> $params = <String, dynamic>{'token': token};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<void>>
  _mypaymentUsersMeWalletDevicesWalletDeviceIdRevokePost({
    required String? walletDeviceId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Revoke a device for the user.

**The user must be authenticated to use this endpoint**''',
      summary: 'Revoke User Devices',
      operationId:
          'revoke_user_devices_mypayment_users_me_wallet_devices__wallet_device_id__revoke_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/mypayment/users/me/wallet/devices/${walletDeviceId}/revoke',
    );
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<History>>> _mypaymentUsersMeWalletHistoryGet({
    String? startDate,
    String? endDate,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get all transactions for the current user\'s wallet.

**The user must be authenticated to use this endpoint**''',
      summary: 'Get User Wallet History',
      operationId:
          'get_user_wallet_history_mypayment_users_me_wallet_history_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment/users/me/wallet/history');
    final Map<String, dynamic> $params = <String, dynamic>{
      'start_date': startDate,
      'end_date': endDate,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<List<History>, History>($request);
  }

  @override
  Future<Response<PaymentUrl>> _mypaymentTransferInitPost({
    required TransferInfo? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Initiate HelloAsso transfer, return a payment url to complete the transaction on HelloAsso website.',
      summary: 'Init Ha Transfer',
      operationId: 'init_ha_transfer_mypayment_transfer_init_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment/transfer/init');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<PaymentUrl, PaymentUrl>($request);
  }

  @override
  Future<Response<PaymentUrl>> _mypaymentTransferRedirectGet({
    required String? url,
    String? checkoutIntentId,
    String? code,
    String? orderId,
    String? error,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''HelloAsso checkout should be configured to redirect the user to:
 - f"{settings.CLIENT_URL}mypayment/transfer/redirect?url={redirect_url}"
Redirect the user to the provided redirect `url`. The parameters `checkoutIntentId`, `code`, `orderId` and `error` passed by HelloAsso will be added to the redirect URL.
The redirect `url` must be trusted by Hyperion in the dotenv.''',
      summary: 'Redirect From Ha Transfer',
      operationId: 'redirect_from_ha_transfer_mypayment_transfer_redirect_get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment/transfer/redirect');
    final Map<String, dynamic> $params = <String, dynamic>{
      'url': url,
      'checkoutIntentId': checkoutIntentId,
      'code': code,
      'orderId': orderId,
      'error': error,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<PaymentUrl, PaymentUrl>($request);
  }

  @override
  Future<Response<AppTypesStandardResponsesResult>>
  _mypaymentStoresStoreIdScanCheckPost({
    required String? storeId,
    required ScanInfo? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Validate if a given QR Code can be scanned by the seller.

The QR Code should be valid, the seller should have the `can_bank` permission for this store,
and the debited wallet device should be active.

If the store structure has an association membership, the user should be a member of the association.

**The user must be authenticated to use this endpoint**''',
      summary: 'Validate Can Scan Qrcode',
      operationId:
          'validate_can_scan_qrcode_mypayment_stores__store_id__scan_check_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment/stores/${storeId}/scan/check');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client
        .send<AppTypesStandardResponsesResult, AppTypesStandardResponsesResult>(
          $request,
        );
  }

  @override
  Future<Response<TransactionBase>> _mypaymentStoresStoreIdScanPost({
    required String? storeId,
    required ScanInfo? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Scan and bank a QR code for this store.

`signature` should be a base64 encoded string
 - signed using *ed25519*,
 - where data are a `QRCodeContentData` object:
    ```
    {
        id: UUID
        tot: int
        iat: datetime
        key: UUID
    }
    ```

The provided content is checked to ensure:
    - the QR Code is not already used
    - the QR Code is not expired
    - the QR Code is intended to be scanned for a store `scan_info.store`
    - the signature is valid and correspond to `wallet_device_id` public key
    - the debited\'s wallet device is active
    - the debited\'s Wallet balance greater than the QR Code total

**The user must be authenticated to use this endpoint**
**The user must have the `can_bank` permission for this store**''',
      summary: 'Store Scan Qrcode',
      operationId: 'store_scan_qrcode_mypayment_stores__store_id__scan_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment/stores/${storeId}/scan');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<TransactionBase, TransactionBase>($request);
  }

  @override
  Future<Response<void>> _mypaymentTransactionsTransactionIdRefundPost({
    required String? transactionId,
    required RefundInfo? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Refund a transaction. Only transactions made in the last 30 days can be refunded.

Currently transactions between users are forbidden and can thus not be refunded.

To cancel a transaction made in the last 30 seconds, the endpoint `/mypayment/transactions/{transaction_id}/cancel` should be used.

**The user must either be the credited user or a seller with cancel permissions of the credited store of the transaction**''',
      summary: 'Refund Transaction',
      operationId:
          'refund_transaction_mypayment_transactions__transaction_id__refund_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/mypayment/transactions/${transactionId}/refund',
    );
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _mypaymentTransactionsTransactionIdCancelPost({
    required String? transactionId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Cancel a transaction.
A transaction can be canceled in the first 30 seconds after it has been created.

To refund an older transaction, use the `/mypayment/transactions/{transaction_id}/refund` endpoint.

**The user must either be the credited user or the seller of the transaction**''',
      summary: 'Cancel Transaction',
      operationId:
          'cancel_transaction_mypayment_transactions__transaction_id__cancel_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/mypayment/transactions/${transactionId}/cancel',
    );
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<Request$>>> _mypaymentRequestsGet({
    bool? used,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get all requests made by the user.

**The user must be authenticated to use this endpoint**''',
      summary: 'Get User Requests',
      operationId: 'get_user_requests_mypayment_requests_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment/requests');
    final Map<String, dynamic> $params = <String, dynamic>{'used': used};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<List<Request$>, Request$>($request);
  }

  @override
  Future<Response<void>> _mypaymentRequestsRequestIdAcceptPost({
    required String? requestId,
    required SignedContent? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Confirm a request.

**The user must be authenticated to use this endpoint**''',
      summary: 'Accept Request',
      operationId: 'accept_request_mypayment_requests__request_id__accept_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment/requests/${requestId}/accept');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _mypaymentRequestsRequestIdRefusePost({
    required String? requestId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Refuse a request.

**The user must be authenticated to use this endpoint**''',
      summary: 'Refuse Request',
      operationId: 'refuse_request_mypayment_requests__request_id__refuse_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment/requests/${requestId}/refuse');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<Invoice>>> _mypaymentInvoicesGet({
    int? page,
    int? pageSize,
    List<dynamic>? structuresIds,
    String? startDate,
    String? endDate,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get all invoices.

**The user must be authenticated to use this endpoint**''',
      summary: 'Get Invoices',
      operationId: 'get_invoices_mypayment_invoices_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment/invoices');
    final Map<String, dynamic> $params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      'structures_ids': structuresIds,
      'start_date': startDate,
      'end_date': endDate,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<List<Invoice>, Invoice>($request);
  }

  @override
  Future<Response<List<Invoice>>> _mypaymentInvoicesStructuresStructureIdGet({
    required String? structureId,
    int? page,
    int? pageSize,
    String? startDate,
    String? endDate,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get all invoices.

**The user must be the structure manager**''',
      summary: 'Get Structure Invoices',
      operationId:
          'get_structure_invoices_mypayment_invoices_structures__structure_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment/invoices/structures/${structureId}');
    final Map<String, dynamic> $params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      'start_date': startDate,
      'end_date': endDate,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<List<Invoice>, Invoice>($request);
  }

  @override
  Future<Response<Invoice>> _mypaymentInvoicesStructuresStructureIdPost({
    required String? structureId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create an invoice for a structure.

**The user must be the bank account holder**''',
      summary: 'Create Structure Invoice',
      operationId:
          'create_structure_invoice_mypayment_invoices_structures__structure_id__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment/invoices/structures/${structureId}');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<Invoice, Invoice>($request);
  }

  @override
  Future<Response<List<int>>> _mypaymentInvoicesInvoiceIdGet({
    required String? invoiceId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Download Invoice',
      operationId: 'download_invoice_mypayment_invoices__invoice_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment/invoices/${invoiceId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<int>, int>($request);
  }

  @override
  Future<Response<void>> _mypaymentInvoicesInvoiceIdDelete({
    required String? invoiceId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Delete a structure invoice.

**The user must be the bank account holder**''',
      summary: 'Delete Structure Invoice',
      operationId:
          'delete_structure_invoice_mypayment_invoices__invoice_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment/invoices/${invoiceId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _mypaymentInvoicesInvoiceIdPaidPatch({
    required String? invoiceId,
    required bool? paid,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Update the paid status of a structure invoice.

**The user must be the bank account holder**''',
      summary: 'Update Invoice Paid Status',
      operationId:
          'update_invoice_paid_status_mypayment_invoices__invoice_id__paid_patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment/invoices/${invoiceId}/paid');
    final Map<String, dynamic> $params = <String, dynamic>{'paid': paid};
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _mypaymentInvoicesInvoiceIdReceivedPatch({
    required String? invoiceId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Update the received status of a structure invoice.

**The user must be the structure manager**''',
      summary: 'Aknowledge Invoice As Received',
      operationId:
          'aknowledge_invoice_as_received_mypayment_invoices__invoice_id__received_patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment/invoices/${invoiceId}/received');
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<IntegrityCheckData>> _mypaymentIntegrityCheckGet({
    String? lastChecked,
    bool? isInitialisation,
    String? xDataVerifierToken,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Send all the MyPayment data for integrity check.
Data includes:
- Wallets deducted of the last 30 seconds transactions
- Transactions with at least 30 seconds delay
- Transfers
- Refunds

**The header must contain the MYPAYMENT_DATA_VERIFIER_ACCESS_TOKEN defined in the settings in the `x-data-verifier-token` field**''',
      summary: 'Get Data For Integrity Check',
      operationId: 'get_data_for_integrity_check_mypayment_integrity_check_get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["MyPayment"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/mypayment/integrity-check');
    final Map<String, dynamic> $params = <String, dynamic>{
      'lastChecked': lastChecked,
      'isInitialisation': isInitialisation,
    };
    final Map<String, String> $headers = {
      if (xDataVerifierToken != null)
        'x-data-verifier-token': xDataVerifierToken,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      headers: $headers,
      tag: swaggerMetaData,
    );
    return client.send<IntegrityCheckData, IntegrityCheckData>($request);
  }

  @override
  Future<Response<String>> _googleApiOauth2callbackGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Google Api Callback',
      operationId: 'google_api_callback_google_api_oauth2callback_get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["GoogleAPI"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/google-api/oauth2callback');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<String, String>($request);
  }

  @override
  Future<Response<List<EventSimple>>> _ticketsEventsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Return all open events.

To be considered open, an event should have its opening date in the past and its closing date in the future or not defined. Moreover, we only return enabled events.''',
      summary: 'Get Open Events',
      operationId: 'get_open_events_tickets_events_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Tickets"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tickets/events');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<EventSimple>, EventSimple>($request);
  }

  @override
  Future<Response<EventPublic>> _ticketsEventsEventIdGet({
    required String? eventId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get an event public details

Only enabled sessions and categories are returned''',
      summary: 'Get Event',
      operationId: 'get_event_tickets_events__event_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Tickets"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tickets/events/${eventId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<EventPublic, EventPublic>($request);
  }

  @override
  Future<Response<CheckoutResponse>> _ticketsEventsEventIdCheckoutPost({
    required String? eventId,
    required Checkout? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Create a checkout for an open event',
      summary: 'Create Checkout',
      operationId: 'create_checkout_tickets_events__event_id__checkout_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Tickets"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tickets/events/${eventId}/checkout');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<CheckoutResponse, CheckoutResponse>($request);
  }

  @override
  Future<Response<List<AppCoreTicketsSchemasTicketsTicketComplete>>>
  _ticketsUserMeTicketsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get all tickets of the current user',
      summary: 'Get User Tickets',
      operationId: 'get_user_tickets_tickets_user_me_tickets_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Tickets"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tickets/user/me/tickets');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<
      List<AppCoreTicketsSchemasTicketsTicketComplete>,
      AppCoreTicketsSchemasTicketsTicketComplete
    >($request);
  }

  @override
  Future<Response<void>> _ticketsUserMeTicketsChangeOverRequestPost({
    required TicketChangeOverInvitation? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Give its ticket to another user. The other user will receive an email with a link to accept the transfer.

Using this endpoint will invalidate existing transfer invitations.''',
      summary: 'Ticket Request Change Over',
      operationId:
          'ticket_request_change_over_tickets_user_me_tickets_change_over_request_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Tickets"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tickets/user/me/tickets/change-over/request');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<dynamic>> _ticketsUserMeTicketsChangeOverAcceptGet({
    required String? token,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Accept a ticket transfer invitation. The user will become the new owner of the ticket.',
      summary: 'Ticket Accept Change Over',
      operationId:
          'ticket_accept_change_over_tickets_user_me_tickets_change_over_accept_get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Tickets"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tickets/user/me/tickets/change-over/accept');
    final Map<String, dynamic> $params = <String, dynamic>{'token': token};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<EventAdmin>> _ticketsAdminEventsEventIdGet({
    required String? eventId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get one event admin details

**The user should have the right to manage the event seller**''',
      summary: 'Get Event Admin',
      operationId: 'get_event_admin_tickets_admin_events__event_id__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Tickets"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tickets/admin/events/${eventId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<EventAdmin, EventAdmin>($request);
  }

  @override
  Future<Response<void>> _ticketsAdminEventsEventIdPatch({
    required String? eventId,
    required EventUpdate? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Edit one event for admin',
      summary: 'Update Event',
      operationId: 'update_event_tickets_admin_events__event_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Tickets"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tickets/admin/events/${eventId}');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _ticketsAdminEventsEventIdDelete({
    required String? eventId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Delete one event for admin',
      summary: 'Delete Event',
      operationId: 'delete_event_tickets_admin_events__event_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Tickets"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tickets/admin/events/${eventId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<EventAdmin>> _ticketsAdminEventsPost({
    required EventCreate? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create an event

**The user should have the right to manage the event seller**''',
      summary: 'Create Event',
      operationId: 'create_event_tickets_admin_events_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Tickets"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tickets/admin/events');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<EventAdmin, EventAdmin>($request);
  }

  @override
  Future<Response<SessionComplete>> _ticketsAdminEventsEventIdSessionsPost({
    required String? eventId,
    required SessionCreate? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a session for an event

**The user should have the right to manage the event seller**''',
      summary: 'Create Session',
      operationId:
          'create_session_tickets_admin_events__event_id__sessions_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Tickets"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tickets/admin/events/${eventId}/sessions');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<SessionComplete, SessionComplete>($request);
  }

  @override
  Future<Response<void>> _ticketsAdminEventsEventIdSessionsSessionIdPatch({
    required String? eventId,
    required String? sessionId,
    required SessionUpdate? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Edit one event for admin',
      summary: 'Update Session',
      operationId:
          'update_session_tickets_admin_events__event_id__sessions__session_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Tickets"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/tickets/admin/events/${eventId}/sessions/${sessionId}',
    );
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _ticketsAdminEventsEventIdSessionsSessionIdDelete({
    required String? eventId,
    required String? sessionId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Delete one session for admin',
      summary: 'Delete Session',
      operationId:
          'delete_session_tickets_admin_events__event_id__sessions__session_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Tickets"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/tickets/admin/events/${eventId}/sessions/${sessionId}',
    );
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<CategoryComplete>> _ticketsAdminEventsEventIdCategoriesPost({
    required String? eventId,
    required CategoryCreate? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a category for an event

**The user should have the right to manage the event seller**''',
      summary: 'Create Category',
      operationId:
          'create_category_tickets_admin_events__event_id__categories_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Tickets"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tickets/admin/events/${eventId}/categories');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<CategoryComplete, CategoryComplete>($request);
  }

  @override
  Future<Response<void>> _ticketsAdminEventsEventIdCategoriesCategoryIdPatch({
    required String? eventId,
    required String? categoryId,
    required CategoryUpdate? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Edit one event for admin',
      summary: 'Update Category',
      operationId:
          'update_category_tickets_admin_events__event_id__categories__category_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Tickets"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/tickets/admin/events/${eventId}/categories/${categoryId}',
    );
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _ticketsAdminEventsEventIdCategoriesCategoryIdDelete({
    required String? eventId,
    required String? categoryId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Delete one category for admin',
      summary: 'Delete Category',
      operationId:
          'delete_category_tickets_admin_events__event_id__categories__category_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Tickets"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/tickets/admin/events/${eventId}/categories/${categoryId}',
    );
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<Question>> _ticketsAdminEventsEventIdQuestionsPost({
    required String? eventId,
    required QuestionCreate? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Create a question for an event

**The user should have the right to manage the event seller**''',
      summary: 'Create Question',
      operationId:
          'create_question_tickets_admin_events__event_id__questions_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Tickets"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tickets/admin/events/${eventId}/questions');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<Question, Question>($request);
  }

  @override
  Future<Response<void>> _ticketsAdminEventsEventIdQuestionsQuestionIdPatch({
    required String? eventId,
    required String? questionId,
    required QuestionUpdate? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Edit one event for admin',
      summary: 'Update Question',
      operationId:
          'update_question_tickets_admin_events__event_id__questions__question_id__patch',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Tickets"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/tickets/admin/events/${eventId}/questions/${questionId}',
    );
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _ticketsAdminEventsEventIdQuestionsQuestionIdDelete({
    required String? eventId,
    required String? questionId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Delete one question for admin',
      summary: 'Delete Question',
      operationId:
          'delete_question_tickets_admin_events__event_id__questions__question_id__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Tickets"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/tickets/admin/events/${eventId}/questions/${questionId}',
    );
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<AppCoreTicketsSchemasTicketsTicket>>>
  _ticketsAdminEventsEventIdTicketsGet({
    required String? eventId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get all tickets of an event

**The user should have the right to manage the event seller**''',
      summary: 'Get Event Tickets',
      operationId:
          'get_event_tickets_tickets_admin_events__event_id__tickets_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Tickets"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tickets/admin/events/${eventId}/tickets');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<
      List<AppCoreTicketsSchemasTicketsTicket>,
      AppCoreTicketsSchemasTicketsTicket
    >($request);
  }

  @override
  Future<Response<List<int>>> _ticketsAdminEventsEventIdTicketsCsvGet({
    required String? eventId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get all tickets of an event as csv

**The user should have the right to manage the event seller**''',
      summary: 'Get Event Tickets Csv',
      operationId:
          'get_event_tickets_csv_tickets_admin_events__event_id__tickets_csv_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Tickets"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tickets/admin/events/${eventId}/tickets/csv');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<int>, int>($request);
  }

  @override
  Future<Response<AppCoreTicketsSchemasTicketsTicket>>
  _ticketsAdminTicketsTicketIdCheckPost({
    required String? ticketId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Check a ticket

**The user should have the right to manage the event seller**''',
      summary: 'Check Ticket',
      operationId: 'check_ticket_tickets_admin_tickets__ticket_id__check_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Tickets"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tickets/admin/tickets/${ticketId}/check');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<
      AppCoreTicketsSchemasTicketsTicket,
      AppCoreTicketsSchemasTicketsTicket
    >($request);
  }

  @override
  Future<Response<void>> _ticketsAdminTicketsTicketIdScanPost({
    required String? ticketId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Mark a ticket as scanned

**The user should have the right to manage the event seller**''',
      summary: 'Scan Ticket',
      operationId: 'scan_ticket_tickets_admin_tickets__ticket_id__scan_post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Tickets"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tickets/admin/tickets/${ticketId}/scan');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<List<EventSimple>>> _ticketsAdminStoreStoreIdEventsGet({
    required String? storeId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Events By Store',
      operationId:
          'get_events_by_store_tickets_admin_store__store_id__events_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Tickets"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/tickets/admin/store/${storeId}/events');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<EventSimple>, EventSimple>($request);
  }

  @override
  Future<Response<List<EventSimple>>>
  _ticketsAdminAssociationAssociationIdEventsGet({
    required String? associationId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Get all events of an association

**The user should have the right to manage the event seller**''',
      summary: 'Get Events By Association',
      operationId:
          'get_events_by_association_tickets_admin_association__association_id__events_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Tickets"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse(
      '/tickets/admin/association/${associationId}/events',
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<EventSimple>, EventSimple>($request);
  }

  @override
  Future<Response<List<String>>> _permissionsListGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Return all permissions from database',
      summary: 'Read Permissions List',
      operationId: 'read_permissions_list_permissions_list_get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Permissions"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/permissions/list');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<String>, String>($request);
  }

  @override
  Future<Response<List<CorePermission>>> _permissionsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Return all permissions from database',
      summary: 'Read Permissions',
      operationId: 'read_permissions_permissions__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Permissions"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/permissions/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<CorePermission>, CorePermission>($request);
  }

  @override
  Future<Response<void>> _permissionsPost({
    required Object? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Create a new permission in database',
      summary: 'Create Permission',
      operationId: 'create_permission_permissions__post',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Permissions"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/permissions/');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<void>> _permissionsDelete({
    required Object? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Delete a permission from database by name',
      summary: 'Delete Permission',
      operationId: 'delete_permission_permissions__delete',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Permissions"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/permissions/');
    final $body = body;
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<void, void>($request);
  }

  @override
  Future<Response<CorePermission>> _permissionsPermissionNameGet({
    required String? permissionName,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Return permission with name from database',
      summary: 'Read Permission',
      operationId: 'read_permission_permissions__permission_name__get',
      consumes: [],
      produces: [],
      security: ["AuthorizationCodeAuthentication"],
      tags: ["Permissions"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/permissions/${permissionName}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<CorePermission, CorePermission>($request);
  }
}
