use v6;

use Test;
plan 40;

# L<S03/List infix precedence/the cross operator>
ok EVAL('<a b> X <c d>'), 'cross non-meta operator parses';

{
    my @result = <a b> X <1 2>;
    is @result, <a 1 a 2 b 1 b 2>,
    'non-meta cross produces expected result';

}

is (1, 2, 3 X** 2, 4), (1, 1, 4, 16, 9, 81), 'X** works';

is ([+] 1, 2, 3 X** 2, 4), (1+1 + 4+16 + 9+81), '[+] and X** work';

# L<S03/List infix precedence/This becomes a flat list in>
{
    my @result = gather {
        for 1..3 X 'a'..'b' -> ($n, $a) {
            take "$n|$a"
        }
    }
    is @result, <1|a 1|b 2|a 2|b 3|a 3|b>, 'smooth cross operator works';
}

# L<S03/List infix precedence/and a list of arrays in>
#?rakudo skip ".slice for iterators NYI RT #124518"
#?niecza skip 'Unable to resolve method slice in class List'
{
    my @result = gather for (1..3 X 'A'..'B').slice -> $na {
        take $na.join(':');
    }
    is @result, <1:A 1:B 2:A 2:B 3:A 3:B>, 'chunky cross operator works';
}

# L<S03/Cross operators>
ok EVAL('<a b> X, <c d>'), 'cross metaoperator parses';

# L<S03/Cross operators/"string concatenating form is">
{
    my @result = <a b> X~ <1 2>;
    is @result, <a1 a2 b1 b2>,
        'cross-concat produces expected result';
}

# L<S03/Cross operators/list concatenating form when used like this>
{
    my @result = <a b> X, 1,2 X, <x y>;
    is @result.elems, 8, 'chained cross-comma produces correct number of elements';

    my @expected = (
        ['a', 1, 'x'],
        ['a', 1, 'y'],
        ['a', 2, 'x'],
        ['a', 2, 'y'],
        ['b', 1, 'x'],
        ['b', 1, 'y'],
        ['b', 2, 'x'],
        ['b', 2, 'y'],
    );
    is @result, @expected, 'chained cross-comma produces correct results';
}

# L<S03/Cross operators/any existing non-mutating infix operator>
is (1,2 X* 3,4), (3,4,6,8), 'cross-product works';

is (1,2 Xcmp 3,2,0), (Order::Less, Order::Less, Order::More, Order::Less, Order::Same, Order::More), 'Xcmp works';

# L<S03/Cross operators/underlying operator non-associating>
eval-dies-ok '@result Xcmp @expected Xcmp <1 2>',
    'non-associating ops cannot be cross-ops';

# let's have some fun with X..., comparison ops and junctions:

{
    ok ( ? all 1, 2 X<= 2, 3, 4 ), 'all @list1 X<= @list2';
    ok ( ? [|] 1, 2 X<= 0, 3),     '[|] @l1 X<= @l2';
    ok ( ! all 1, 2 X<  2, 3),     'all @l1 X<  @l2';
    ok ( ? one 1, 2 X== 2, 3, 4),  'one @l1 X== @l2';
    ok ( ! one 1, 2 X== 2, 1, 4),  'one @l1 X== @l2';
}

{
    my ($a, $b, $c, $d);
    # test that the containers on the LHS are mutually exclusive from
    # those on the RHS
    ok ( ? all $a, $b X!=:= $c, $d ), 'X!=:= (1)';
    ok ( ? all $a, $a X!=:= $c, $d ), 'X!=:= (2)';
    ok ( ! all $a, $b X!=:= $c, $b ), 'X!=:= (3)';
    $c := $b;
    ok ( ? one $a, $b X=:=  $c, $d ), 'one X=:=';
}

# tests for non-list arguments
is (1 X* 3,4), (3, 4), 'cross-product works with scalar left side';
is (1, 2 X* 3), (3, 6), 'cross-product works with scalar right side';
is (1 X* 3), (3), 'cross-product works with scalar both sides';

is (<a b> X <c d> X < e f>).flat.join(','),
    'a,c,e,a,c,f,a,d,e,a,d,f,b,c,e,b,c,f,b,d,e,b,d,f',
    'cross works with three lists';

#?niecza todo
is ($[1,2] X~ <a b>), '1 2a 1 2b', '$[] does not flatten';

is (1,2 X (<a b> X "x")).flat.join, '1ax1bx2ax2bx',
    'Nested X works';

# RT #77660
{
    my @a = 1,2,3;
    @a X*= 10;
    is ~@a, '10 20 30', 'cross can modify containers on the left';
}

# RT #112602
{
    is (1..* X* 1..*)[^3], (1, 2, 3), 'cross handles lazy lists';
}

# RT #77114
{
    eval-dies-ok 'my %foo XX= 1', "cross doesn't handle assignment";
}

# RT #120973
{
    my @rt120973 = <a b> X <1 2>.map({$_});
    is @rt120973, <a 1 a 2 b 1 b 2>,
    'cross product with a .map in the rhs produces expected result';

    @rt120973 = <a b>.map({$_}) X <1 2>;
    is @rt120973, <a 1 a 2 b 1 b 2>,
    'cross product with a .map in lhs produces expected result';

    @rt120973 = <a b>.map({$_}) X <1 2>.map({$_});
    is @rt120973, <a 1 a 2 b 1 b 2>,
    'cross product with a .map in lhs and rhs produces expected result';
}

{
    ok (1..* X* 42).is-lazy, "laziness induced by first argument";
    ok (42 X* 1..*).is-lazy, "laziness induced by last argument";
    ok (42 X* 1..* X* 43).is-lazy, "laziness induced by middle argument";
    ok !(1..5 X* 42).is-lazy, "laziness not induced by first argument";
    ok !(42 X* 1..5).is-lazy, "laziness not induced by last argument";
    ok !(42 X* 1..5 X* 43).is-lazy, "laziness not induced by middle argument";
}

# vim: ft=perl6
