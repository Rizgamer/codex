-- LaneCombat has no client state: a defender only sees the active enemy in its own lane.
local Combat={}
function Combat.TryAttack(defender, enemy, now)
 if not enemy or enemy.Dead or now < defender.NextAttack then return false end
 if (defender.Model.Position-enemy.Model.Position).Magnitude > defender.Range then return false end
 defender.NextAttack=now+defender.Cooldown
 local damage=defender.Damage
 if Random.new():NextNumber()<defender.Crit then damage*=defender.CritMultiplier end
 enemy.Health-=damage
 return true
end
return Combat
