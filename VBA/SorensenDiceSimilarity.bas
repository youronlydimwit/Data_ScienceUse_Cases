Attribute VB_Name = "Module3"
Function SimilaritySorensenDiceCoef(s1 As String, s2 As String) As Double
    Dim set1 As Object
    Set set1 = CreateObject("Scripting.Dictionary")
    
    Dim set2 As Object
    Set set2 = CreateObject("Scripting.Dictionary")
    
    Dim i As Integer
    
    ' Create sets of characters from both strings
    For i = 1 To Len(s1)
        set1(Mid(s1, i, 1)) = 1
    Next i
    
    For i = 1 To Len(s2)
        set2(Mid(s2, i, 1)) = 1
    Next i
    
    ' Calculate the size of the intersection of the sets
    Dim intersectionSize As Integer
    intersectionSize = 0
    
    For Each Key In set1.Keys
        If set2.Exists(Key) Then
            intersectionSize = intersectionSize + 1
        End If
    Next Key
    
    ' Calculate the Sørensen-Dice coefficient
    Dim coefficient As Double
    
    If set1.Count + set2.Count = 0 Then
        coefficient = 1
    Else
        coefficient = 2 * intersectionSize / (set1.Count + set2.Count)
    End If
    
    SimilaritySorensenDiceCoef = coefficient
End Function
