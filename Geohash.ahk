class Geohash
{
	static base32 := "0123456789bcdefghjkmnpqrstuvwxyz"
	
	encode(lat, lon, precision = false) {
		if !precision
		{
			Loop, 12
			{
				hash := this.encode(lat, lon, A_Index)
				posn := this.decode(hash)
				if (posn.lat = lat && posn.lon = lon) {
					return hash
				}
			}
			precision := 12
		}
		
		if !lat || !lon || !precision
		{
			Throw, Invalid geohash
		}
		
		idx := 0
		bit := 0
		evenBit := true
		geohash_ := ""
		
		latMin :=  -90, latMax :=  90
		lonMin := -180, lonMax := 180
		
		while(StrLen(geohash_) < precision) {
			if (evenBit) {
				; bisect E-W longitude
				lonMid := (lonMin + lonMax) / 2
				if (lon >= lonMid) {
					idx := idx*2 + 1
					lonMin := lonMid
				}
				else {
					idx := idx*2
					lonMax := lonMid
				}
			}
			else {
				; bisect N-S latitude
				latMid := (latMin + latMax) / 2
				if (lat >= latMid) {
					idx := idx*2 + 1
					latMin := latMid
				}
				else {
					idx := idx*2
					latMax := latMid
				}
			}
			evenBit := !evenBit
			
			if (++bit == 5) {
				geohash_ .= SubStr(this.base32, idx+1, 1)
				bit := 0
				idx := 0
			}
		}
		
		return geohash_
	}
	
	decode(geohash_) {
		bounds := this.bounds(geohash_)
		; now just determine the centre of the cell...
		
		latMin := bounds.sw.lat, lonMin := bounds.sw.lon
		latMax := bounds.ne.lat, lonMax := bounds.ne.lon
		
		; cell centre
		lat := (latMin + latMax) / 2
		lon := (lonMin + lonMax) / 2
		
		; round to close to centre without excessive precision: ⌊2-log10(Δ°)⌋ decimal places
		lat := Format("{:." Floor(2-Log(latMax-latMin)/Ln(10)) "f}", lat)
		lon := Format("{:." Floor(2-Log(lonMax-lonMin)/Ln(10)) "f}", lon)
		
		return {lat: lat, lon: lon}
	}
	
	bounds(geohash_) {
		if !geohash_ {
			Throw, Invalid geohash
		}
		
		StringLower, geohash_, geohash_
		
		evenBit := true
		latMin :=  -90, latMax :=  90
		lonMin := -180, lonMax := 180
		
		Loop, Parse, geohash_
		{
			chr := A_LoopField
			idx := InStr(this.base32, chr)
			if !idx
				Throw, Invalid geohash
			
			Loop, 5
			{
				n := 5 - A_Index
				bitN := ( idx-1 ) >> n & 1
				if evenBit {
					; longitude
					lonMid := (lonMin + lonMax) / 2
					if (bitN = 1) {
						lonMin := lonMid
					}
					else {
						lonMax := lonMid
					}
				}
				else {
					; latitude
					latMid := (latMin + latMax) / 2
					if (bitN = 1) {
						latMin := latMid
					}
					else {
						latMax := latMid
					}
				}
				evenBit := !evenBit
			}
		}
		
		bounds := {sw:{lat:latMin, lon:lonMin}, ne:{lat:latMax, lon:lonMax}}
		return bounds
	}
	
	adjacent(geohash_, direction) {
		; based on github.com/davetroy/geohash_-js
		
		StringLower, geohash_, geohash_
		StringLower, direction, direction
		
		if !geohash_
			Throw, Invalid geohash
		If !InStr("nsew", direction)
			Throw, Invalid direction
		
		neighbour := { n: [ "p0r21436x8zb9dcf5h7kjnmqesgutwvy", "bc01fg45238967deuvhjyznpkmstqrwx" ]
		,s: [ "14365h7k9dcfesgujnmqp0r2twvyx8zb", "238967debc01fg45kmstqrwxuvhjyznp" ]
		,e: [ "bc01fg45238967deuvhjyznpkmstqrwx", "p0r21436x8zb9dcf5h7kjnmqesgutwvy" ]
		,w: [ "238967debc01fg45kmstqrwxuvhjyznp", "14365h7k9dcfesgujnmqp0r2twvyx8zb" ] }
		
		border := { n: [ "prxz", "bcfguvyz" ]
		,s: [ "028b", "0145hjnp" ]
		,e: [ "bcfguvyz", "prxz" ]
		,w: [ "0145hjnp", "028b" ] }
		
		lastCh := SubStr(geohash_, StrLen(geohash_))
		parent := SubStr(geohash_, 1, StrLen(geohash_)-1)
		
		type := Mod( StrLen(geohash_), 2 )
		
		; check for edge-cases which don't share common prefix
		if (InStr(border[direction][type], lastCh) && parent) {
			parent := this.adjacent(parent, direction)
		}
		
		; append letter for direction to parent
		return parent . SubStr(this.base32, InStr(neighbour[direction][type], lastCh), 1)
	}
	
	neighbours(geohash_) {
		result := {n:"", ne:"", e:"", se:"", s:"", sw:"", w:"", nw:""}
		for key in result
		{
			val := geohash_
			Loop, Parse, key
			{
				val := this.adjacent(val, A_LoopField)
			}
			result[key] := val
		}
		return result
	}
}