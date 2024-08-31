import math

WAD = 1e18  # 18 decimals for fixed-point precision


def mul_wad(x, y):
    return (x * y) // WAD


def exp_wad(x):
    return int(math.exp(x / WAD) * WAD)


def ln_wad(x):
    return int(math.log(x / WAD) * WAD)


def full_mul_div(x, y, z):
    return (x * y) // z


def price_at_curve(a, b, x):
    exp_b_x = exp_wad(mul_wad(b, x))
    return mul_wad(a, exp_b_x)


def getFundsNeeded(a, b, x0, deltaX):
    # Calculate exp(b * x0) and exp(b * x1)
    exp_b_x0 = exp_wad(mul_wad(b, x0))
    exp_b_x1 = exp_wad(mul_wad(b, x0 + deltaX))

    # Calculate deltaY = (a/b) * (e^(b * x1) - e^(b * x0))
    delta = exp_b_x1 - exp_b_x0
    deltaY = full_mul_div(a, delta, b)

    return deltaY


def getAmountOut(a, b, x0, deltaY):
    # Calculate exp(b * x0)
    exp_b_x0 = exp_wad(mul_wad(b, x0))

    # Calculate exp(b * x0) + (dy*b/a)
    exp_b_x1 = exp_b_x0 + full_mul_div(deltaY, b, a)

    # Calculate ln(x1)/b - x0
    deltaX = full_mul_div(ln_wad(exp_b_x1), WAD, b) - x0

    return deltaX


def get_total_amount(a, b, y):
    return getAmountOut(a, b, 0, y)


def get_total_funds(a, b, x):
    return getFundsNeeded(a, b, 0, x)


def calc_a_from_b(b, delta_x, delta_y):
    bx = mul_wad(b, delta_x)
    print(f"x: {bx/WAD}")
    exp_b_x = exp_wad(bx)
    print(f"exp_term: {exp_b_x/WAD}")
    a = full_mul_div(delta_y, b, exp_b_x - 1 * WAD)
    return a


if __name__ == "__main__":
    b = 74866472  # 10^-9
    delta_z = 69_000_000_000 * WAD
    delta_x = delta_z * 4 / 5
    delta_y = 100_000 * WAD

    # b = 5000000000  # 10^-9
    # delta_z = 1_000_000_000 * WAD
    # delta_x = delta_z * 4 / 5
    # delta_y = 69_000 * WAD

    a = int(calc_a_from_b(b, delta_x, delta_y)) + 1
    print(f"b = {b}")
    print(f"a = {a}")

    all_y = getFundsNeeded(a, b, 0, delta_x)
    print(f"by all token, you need ETH: all_y = {all_y / WAD}")
    all_x = getAmountOut(a, b, 0, delta_y)
    print(f"use all ETH, you will get token: all_x = {int(all_x)/WAD}")

    # amounts = []
    # step = 10_000_000 * WAD
    # for i in range(1, 80):
    #     amount = getFundsNeeded(a, b, (i - 1) * step, step) / WAD
    #     print(amount)
    #     amounts.append(amount)

    # print(sum(amounts))
    print("For each 5000 ETH, you will get token: ")
    count = 20
    amount = 0
    for i in range(1, count + 1):
        pre = amount
        amount += getAmountOut(a, b, amount, delta_y / count)
        price = delta_y / count / (amount - pre)
        print(delta_y / count / WAD, f"{round(amount / WAD, 2):.2f}", f"{(amount - pre) / WAD:14.2f}" , f"    {price}")

    print("price when add liquidity : ", delta_y / (delta_z - delta_x))
    print("price at curve end: ", price_at_curve(a, b, delta_x) / WAD)
    # print("Token needed for add liquidity(actually): ", delta_y / price_at_curve(a, b, delta_x))
