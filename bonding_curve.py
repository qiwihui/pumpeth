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
    x = mul_wad(b, delta_x)
    print(f"x: {x/WAD}")
    exp_term = exp_wad(x)
    print(f"exp_term: {exp_term/WAD}")
    a = full_mul_div(delta_y, b, exp_term - 1 * WAD)
    return a


if __name__ == "__main__":
    b = 1_000_000_000 # 10^
    delta_x = 800_000_000 * WAD  # 800 M
    delta_y = 20 * WAD
    a = int(calc_a_from_b(b, delta_x, delta_y)) + 1
    print(f"a = {a}")

    all_y = getFundsNeeded(a, b, 0, delta_x)
    print(f"all_y = {all_y / WAD}")
    all_x = getAmountOut(a, b, 0, delta_y)
    print(f"all_x = {int(all_x)}")

    # amounts = []
    # step = 10_000_000 * WAD
    # for i in range(1, 80):
    #     amount = getFundsNeeded(a, b, (i - 1) * step, step) / WAD
    #     print(amount)
    #     amounts.append(amount)

    # print(sum(amounts))

    # amount = 0
    # for i in range(1, 21):
    #     pre = amount
    #     amount += getAmountOut(a, b, amount, 1 * WAD)
    #     print(amount/WAD, (amount - pre)/WAD)