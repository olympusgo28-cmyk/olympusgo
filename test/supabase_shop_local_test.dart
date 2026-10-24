// Runs the real shop repository against a local Supabase stack (never the
// hosted project). Skipped unless LOCAL_SUPABASE_URL and LOCAL_SUPABASE_KEY
// point at `supabase start` running locally.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:olympus_go/features/shop/data/shop_repository.dart';
import 'package:olympus_go/features/shop/domain/commerce_models.dart';
import 'package:olympus_go/features/shop/domain/shop_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final url = Platform.environment['LOCAL_SUPABASE_URL'];
  final key = Platform.environment['LOCAL_SUPABASE_KEY'];
  final skip = url == null || key == null || !url.contains('127.0.0.1')
      ? 'Needs a local Supabase stack'
      : null;

  Future<SupabaseShopRepository> player(String name) async {
    final client = SupabaseClient(
      url!,
      key!,
      authOptions: const AuthClientOptions(
        autoRefreshToken: false,
        authFlowType: AuthFlowType.implicit,
      ),
    );
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final res = await client.auth.signUp(
      email: '$name.$stamp@test.local',
      password: 'test-password-123',
    );
    await client
        .from('profiles')
        .update({
          'username': '${name}_${stamp % 100000}',
          'full_name': '$name Test',
          'onboarding_completed': true,
        })
        .eq('id', res.user!.id);
    await client.from('player_sports').insert({
      'user_id': res.user!.id,
      'sport': 'badminton',
      'level': 5,
      'play_min': 1,
      'play_max': 8,
    });
    return SupabaseShopRepository(client);
  }

  test(
    'a shop from opening to a review and a return, against local Supabase',
    () async {
      final stamp = DateTime.now().millisecondsSinceEpoch % 100000;
      final seller = await player('seller');
      final buyer = await player('buyer');

      expect(await seller.sellerSummary(), isNull);
      await seller.openShop(
        name: 'Racket Lab $stamp',
        blurb: 'Rackets and restringing',
        about: 'In Tampines',
        shipsFrom: 'Tampines',
      );
      await expectLater(
        seller.openShop(name: 'Again', blurb: '', about: '', shipsFrom: ''),
        throwsA(isA<Object>()),
      );
      final shop = (await seller.sellerSummary())!;
      expect(shop.mall.name, 'Racket Lab $stamp');
      expect(shop.mall.initials, 'RL');

      const base = Product(
        id: '',
        name: '',
        mallId: '',
        mallName: '',
        priceCents: 0,
      );
      final racket = await seller.saveProduct(
        base.copyWith(
          name: 'Carbon racket 4U',
          description: 'Head-light\nFor fast doubles',
          priceCents: 18900,
          stock: 3,
          published: true,
        ),
      );
      final draft = await seller.saveProduct(
        base.copyWith(
          name: 'Secret bag',
          priceCents: 5000,
          stock: 5,
          published: false,
        ),
      );
      final restring = await seller.saveProduct(
        base.copyWith(
          name: 'Restring service',
          priceCents: 2500,
          service: true,
          published: true,
        ),
      );
      expect(await seller.sellerProducts(), hasLength(3));

      // Buyers see what's listed, not drafts.
      final listed = await buyer.products(mallId: shop.mall.id);
      expect(listed.map((p) => p.id), containsAll([racket.id, restring.id]));
      expect(listed.map((p) => p.id), isNot(contains(draft.id)));
      expect(
        (await buyer.products(query: 'carbon racket')).map((p) => p.id),
        contains(racket.id),
      );
      expect((await buyer.malls()).map((m) => m.id), contains(shop.mall.id));
      final detail = await buyer.product(racket.id);
      expect(detail.about.take(2), ['Head-light', 'For fast doubles']);
      await expectLater(buyer.product(draft.id), throwsA(isA<Object>()));
      await expectLater(seller.addToCart(racket.id), throwsA(isA<Object>()));

      await buyer.follow(shop.mall.id, true);
      expect((await buyer.mall(shop.mall.id)).followers, 1);

      // Cart and checkout.
      await buyer.addToCart(racket.id, variant: '4U', qty: 2);
      await buyer.addToCart(racket.id, variant: '4U');
      var cart = await buyer.cart();
      expect(cart.single.qty, 3);
      await buyer.setQty(cart.single.id, 2);
      cart = await buyer.cart();
      expect(cart.single.totalCents, 37800);

      final home = await buyer.saveAddress(
        const Address(
          id: '',
          label: 'Home',
          name: 'Buyer Test',
          line: '21 Tampines Ave 1',
          isDefault: true,
        ),
      );
      expect((await buyer.addresses()).single.id, home.id);

      final placed = await buyer.checkout(
        address: home,
        delivery: Delivery.options.first,
        pointsCents: 0,
        paidWith: 'Pay the shop',
      );
      expect(placed, hasLength(1));
      final order = placed.single;
      expect(order.step, OrderStep.packing);
      expect(order.paidWith, 'Pay the shop');
      expect(order.deliveryCents, 199);
      expect(order.totalCents, 37800 + 199);
      expect(await buyer.cart(), isEmpty);
      expect(
        (await seller.sellerProducts())
            .firstWhere((p) => p.id == racket.id)
            .stock,
        1,
      );
      // Only 1 left, so 2 more can't be bought.
      await expectLater(
        buyer.checkout(
          address: home,
          delivery: Delivery.options.first,
          pointsCents: 0,
          paidWith: 'Pay the shop',
          only: CartLine(id: 'x', product: racket, qty: 2),
        ),
        throwsA(isA<Object>()),
      );

      // The seller ships it, the buyer gets it.
      final summary = (await seller.sellerSummary())!;
      expect(summary.toShip, 1);
      expect(summary.salesTodayCents, 37800);
      expect((await seller.sellerOrders()).single.buyer, 'buyer Test');
      await expectLater(
        buyer.markShipped(order.id, courier: 'X', tracking: '1'),
        throwsA(isA<Object>()),
      );
      await seller.markShipped(order.id, courier: 'Ninja Van', tracking: 'NV1');
      await expectLater(
        buyer.cancelOrder(order.id, reason: 'Late', toWallet: true),
        throwsA(isA<Object>()),
      );
      await buyer.confirmReceived(order.id);
      var mine = await buyer.order(order.id);
      expect(mine.step, OrderStep.delivered);
      expect(mine.courier, 'Ninja Van');

      // Review and return.
      await buyer.review(
        order.id,
        stars: 4,
        tags: ['Good value'],
        text: 'Light and fast',
        showLevel: true,
      );
      await expectLater(
        buyer.review(order.id, stars: 5, tags: [], text: '', showLevel: false),
        throwsA(isA<Object>()),
      );
      final reviewed = await buyer.product(racket.id);
      expect(reviewed.product.rating, 4.0);
      expect(reviewed.product.sold, 2);
      expect(reviewed.reviews.single.text, 'Light and fast');
      expect(reviewed.reviews.single.meta, contains('Badminton'));

      await buyer.requestReturn(order.id, reason: 'Wrong size', want: 'Refund');
      mine = await buyer.order(order.id);
      expect(mine.reviewed, isTrue);
      expect(mine.returnState, 'requested');
      expect((await seller.sellerSummary())!.returns, 1);
      await seller.decideReturn(order.id, accept: true);
      expect((await buyer.order(order.id)).returnState, 'accepted');
      expect(
        (await seller.sellerProducts())
            .firstWhere((p) => p.id == racket.id)
            .stock,
        3,
      );

      // Cancel before shipping puts stock back.
      final second = (await buyer.checkout(
        address: home,
        delivery: Delivery.options.last,
        pointsCents: 0,
        paidWith: 'Pay the shop',
        only: CartLine(id: 'x', product: racket),
      )).single;
      expect(second.deliveryCents, 0);
      expect(
        await buyer.cancelOrder(
          second.id,
          reason: 'Changed my mind',
          toWallet: true,
        ),
        0,
      );
      expect((await buyer.order(second.id)).step, OrderStep.cancelled);
      expect(
        (await seller.sellerProducts())
            .firstWhere((p) => p.id == racket.id)
            .stock,
        3,
      );

      // A booked service, made ready.
      final booking = await buyer.bookService(
        restring.id,
        slot: 'Sat 10:00 AM',
        tension: '24 lb',
      );
      expect(booking.service, isTrue);
      expect(booking.booking, 'Sat 10:00 AM');
      await seller.markShipped(booking.id, courier: '', tracking: '');
      expect((await buyer.order(booking.id)).step, OrderStep.shipped);

      // Strangers can't see the order, and reports are stored.
      final other = await player('other');
      await expectLater(other.order(order.id), throwsA(isA<Object>()));
      await other.report('Order: x', reason: 'Fake item', note: 'test');
      expect(await buyer.orders(), hasLength(3));
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
