total_health = 100

sword_damage = 15

mele_damage = 5

health_potion = 20

total_health = (total_health - sword_damage)
print(f"you have {total_health} health remaining")

total_health = (total_health - (mele_damage * 2))
print(f'you have {total_health} health remaining')

total_health = total_health + health_potion
print(f'health restored to {total_health}, HUZZAH! ')